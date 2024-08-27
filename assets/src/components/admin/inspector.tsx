import React, {
  type ComponentType,
  type RefObject,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import { useHistory, useLocation } from "react-router-dom";

import AdminForm from "./admin_form";

import { doSubmit, type Config, type Screen } from "Util/admin";
import {
  type Message,
  INSPECTOR_FRAME_NAME,
  sendMessage,
  useReceiveMessage,
} from "Util/inspector";

type ScreenWithId = { id: string; config: Screen };

const SCREEN_TYPES = new Set([
  "bus_eink_v2",
  "bus_shelter_v2",
  "busway_v2",
  "dup_v2",
  "gl_eink_v2",
  "pre_fare_v2",
]);

const AUDIO_SCREEN_TYPES = new Set([
  "bus_shelter_v2",
  "busway_v2",
  "gl_eink_v2",
  "pre_fare_v2",
]);

const Inspector: ComponentType = () => {
  const [config, setConfig] = useState<Config | null>(null);

  useEffect(() => {
    fetch("/api/admin")
      .then((result) => result.json())
      .then((json) => JSON.parse(json.config))
      .then((config) => setConfig(config))
      .catch(() => alert("Failed to load config!"));
  }, []);

  const { search } = useLocation();
  const screenId = new URLSearchParams(search).get("id");
  const screen: ScreenWithId | null =
    config && screenId
      ? { id: screenId, config: config.screens[screenId] }
      : null;

  const [isSimulation, setIsSimulation] = useState(false);

  const frameRef = useRef<HTMLIFrameElement>(null);

  const sendToFrame = (message: Message) => {
    const frameWindow = frameRef.current?.contentWindow;
    frameWindow && sendMessage(frameWindow, message);
  };

  const [zoom, setZoom] = useState(1.0);
  const adjustFrame = () => adjustScreenFrame(frameRef, isSimulation, zoom);
  useLayoutEffect(adjustFrame, [zoom]);

  return (
    <div className="viewer">
      <div className="viewer__controls">
        <h1>Inspector</h1>

        {config && (
          <>
            <ScreenSelector
              config={config}
              screen={screen}
              isSimulation={isSimulation}
              setIsSimulation={setIsSimulation}
            />

            {screen && (
              <>
                <ConfigControls screen={screen} />
                <ViewControls zoom={zoom} setZoom={setZoom} />
                <DataControls sendToFrame={sendToFrame} />
                <AudioControls config={config} screen={screen} />
              </>
            )}
          </>
        )}
      </div>

      <div className="viewer__screen">
        <iframe
          name={INSPECTOR_FRAME_NAME}
          onLoad={adjustFrame}
          ref={frameRef}
          src={
            screen
              ? new URL(
                  `/v2/screen/${screen.id}${isSimulation ? "/simulation" : ""}`,
                  location.origin,
                ).toString()
              : "about:blank"
          }
        ></iframe>
      </div>
    </div>
  );
};

const ScreenSelector: ComponentType<{
  config: Config;
  screen: ScreenWithId | null;
  isSimulation: boolean;
  setIsSimulation: (value: boolean) => void;
}> = ({ config, screen, isSimulation, setIsSimulation }) => {
  const history = useHistory();
  const { pathname, search } = useLocation();

  const navigateToScreen = (id) => {
    const params = new URLSearchParams(search);
    params.set("id", id);
    history.push({ pathname, search: params.toString() });
  };

  const screensByType: Record<string, ScreenWithId[]> = Object.entries(
    config.screens,
  )
    .filter(([, { app_id }]) => SCREEN_TYPES.has(app_id))
    .sort(([idA], [idB]) => idA.localeCompare(idB))
    .reduce((groups, [id, config]) => {
      groups[config.app_id] ||= [];
      groups[config.app_id].push({ id, config });
      return groups;
    }, {});

  return (
    <fieldset>
      <legend>Screen</legend>

      <select
        value={screen?.id}
        onChange={(event) => navigateToScreen(event.target.value)}
      >
        <option></option>
        {Object.keys(screensByType).map((type) => (
          <optgroup label={type} key={type}>
            {screensByType[type].map(({ id, config: { name } }) => (
              <option value={id} key={id}>
                {id}
                {name ? ` · ${name}` : ""}
              </option>
            ))}
          </optgroup>
        ))}
      </select>

      <label>
        <input
          type="checkbox"
          checked={isSimulation}
          onChange={() => setIsSimulation(!isSimulation)}
        />
        Screenplay Simulation
      </label>
    </fieldset>
  );
};

const ConfigControls: ComponentType<{ screen: ScreenWithId }> = ({
  screen,
}) => {
  const [editableConfig, setEditableConfig] = useState<Screen | null>(null);
  const [isRequestingReload, setIsRequestingReload] = useState(false);
  const dialogRef = useRef<HTMLDialogElement>(null);

  return (
    <fieldset>
      <legend>Configuration</legend>

      <div>
        <button
          onClick={() => {
            setEditableConfig(screen.config);
            dialogRef.current?.showModal();
          }}
        >
          Edit Config
        </button>

        <button
          disabled={isRequestingReload}
          onClick={() => {
            setIsRequestingReload(true);
            doSubmit("/api/admin/refresh", { screen_ids: [screen.id] })
              .then(() => alert("Scheduled a reload for this screen."))
              .finally(() => setIsRequestingReload(false));
          }}
        >
          Schedule Page Reload
        </button>
      </div>

      <dialog className="viewer__modal" ref={dialogRef}>
        <button
          className="viewer__modal__close-button"
          onClick={() => {
            dialogRef.current?.close();
            setEditableConfig(null);
          }}
        >
          × Cancel
        </button>

        <p>
          ⚠️ <b>Warning:</b> This will update the live config for this screen.
        </p>

        {editableConfig && (
          <AdminForm
            fetchConfig={async () => editableConfig}
            validatePath={`/api/admin/screens/validate/${screen.id}`}
            confirmPath={`/api/admin/screens/confirm/${screen.id}`}
          />
        )}
      </dialog>
    </fieldset>
  );
};

const ViewControls: ComponentType<{
  zoom: number;
  setZoom: (zoom: number) => void;
}> = ({ zoom, setZoom }) => {
  return (
    <fieldset>
      <legend>View</legend>

      <div>
        <button disabled={zoom <= 0.25} onClick={() => setZoom(zoom - 0.25)}>
          ➖
        </button>
        <button onClick={() => setZoom(zoom + 0.25)}>➕</button>
        <button onClick={() => setZoom(1.0)}>Reset</button>
        <div>({zoom}x)</div>
      </div>
    </fieldset>
  );
};

const DataControls: ComponentType<{
  sendToFrame: (message: Message) => void;
}> = ({ sendToFrame }) => {
  const [dataTimestamp, setDataTimestamp] = useState<number | null>(null);
  const [dataSecondsOld, setDataSecondsOld] = useState<number | null>(null);
  const [isRefreshEnabled, setIsRefreshEnabled] = useState(true);

  useReceiveMessage((message) => {
    if (message.type == "data_refreshed") {
      setDataTimestamp(message.timestamp);
      setDataSecondsOld(0);
    }
  });

  useEffect(() => {
    const interval = setInterval(() => {
      setDataSecondsOld(
        dataTimestamp ? Math.round((Date.now() - dataTimestamp) / 1000) : null,
      );
    }, 1000);
    return () => clearInterval(interval);
  }, [dataTimestamp]);

  useEffect(() => {
    sendToFrame({ type: "set_refresh_rate", ms: isRefreshEnabled ? null : 0 });
  }, [isRefreshEnabled]);

  return (
    <fieldset>
      <legend>Data</legend>

      <div>
        <button onClick={() => sendToFrame({ type: "refresh_data" })}>
          Refresh
        </button>

        {isRefreshEnabled && dataSecondsOld != null && (
          <span>⏱️ {dataSecondsOld} seconds ago</span>
        )}
      </div>

      <label>
        <input
          type="checkbox"
          checked={isRefreshEnabled}
          onChange={() => setIsRefreshEnabled(!isRefreshEnabled)}
        />
        Enable refresh interval
      </label>
    </fieldset>
  );
};

const AudioControls: ComponentType<{
  config: Config;
  screen: ScreenWithId;
}> = ({ config, screen }) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [ssml, setSSML] = useState<string | null>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(
    () => (ssml ? dialogRef.current?.showModal() : dialogRef.current?.close()),
    [dialogRef, ssml],
  );

  let audioPath: string | null = null;
  let v1ScreenId: string | null = null;

  if (AUDIO_SCREEN_TYPES.has(screen.config.app_id)) {
    // Temporarily special-case Busway screens while V2 doesn't support audio
    // yet, in a way that aligns with how they're configured in reality (using
    // the audio endpoint of a corresponding V1 screen).
    if (screen.config.app_id == "busway_v2") {
      const maybeV1Id = screen.id.replace(/-V2$/, "");

      if (maybeV1Id != screen.id && config.screens[maybeV1Id]) {
        audioPath = `/audio/${maybeV1Id}`;
        v1ScreenId = maybeV1Id;
      }
    } else {
      audioPath = `/v2/audio/${screen.id}`;
    }
  }

  return (
    <fieldset>
      <legend>Audio</legend>

      {audioPath ? (
        <>
          <div>
            <button
              onClick={() => {
                setSSML("Loading...");
                fetch(`${audioPath}/debug`)
                  .then((result) => result.text())
                  .then((text) => setSSML(text))
                  .catch(() => alert("Failed to fetch SSML!"));
              }}
            >
              Show SSML
            </button>

            <button onClick={() => setIsPlaying(!isPlaying)}>
              {isPlaying ? "⏹️ Stop Audio" : "▶️ Play Audio"}
            </button>
          </div>

          {v1ScreenId && (
            <div>
              <span>
                (from v1 screen <code>{v1ScreenId}</code>)
              </span>
            </div>
          )}

          <dialog className="viewer__modal" ref={dialogRef}>
            <button
              className="viewer__modal__close-button"
              onClick={() => setSSML(null)}
            >
              × Close
            </button>
            <div className="viewer__modal__ssml">{ssml}</div>
          </dialog>

          {isPlaying && (
            <audio
              autoPlay={true}
              onEnded={() => setIsPlaying(false)}
              src={`${audioPath}/readout.mp3`}
            />
          )}
        </>
      ) : (
        <div>Not supported on this screen</div>
      )}
    </fieldset>
  );
};

const adjustScreenFrame = (
  ref: RefObject<HTMLIFrameElement>,
  isSimulation: boolean,
  zoom: number,
) => {
  if (ref.current?.contentWindow) {
    const doc = ref.current.contentWindow.document;
    let style = doc.getElementById("viewer-injected-style");

    if (!style) {
      style = doc.createElement("style");
      style.id = "viewer-injected-style";
      doc.head.appendChild(style);
    }

    const className = isSimulation
      ? "simulation-screen-scrolling-container"
      : "screen-container";

    style.innerHTML = `
      .screen-container {
        margin: unset;
      }
      .simulation-screen-centering-container {
        justify-content: unset;
      }
      .${className} {
        transform: scale(${zoom});
        transform-origin: top left;
      }
    `;

    ref.current.height = doc.body.scrollHeight.toString();
    ref.current.width = doc.body.scrollWidth.toString();
  }
};

export default Inspector;
