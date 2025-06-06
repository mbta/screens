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

import { type AudioConfig } from "Components/v2/screen_container";

import { fetch, type Config, type Screen } from "Util/admin";
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
  "elevator_v2",
  "gl_eink_v2",
  "pre_fare_v2",
]);

const AUDIO_SCREEN_TYPES = new Set([
  "bus_eink_v2",
  "bus_shelter_v2",
  "busway_v2",
  "gl_eink_v2",
  "pre_fare_v2",
]);

const SCREEN_TYPE_VARIANTS = { dup_v2: ["new_departures"] };

const buildIframeUrl = (
  screen: ScreenWithId | null,
  isSimulation: boolean,
  isVariantEnabled: boolean,
) => {
  if (screen) {
    const pathSuffix = isSimulation ? "/simulation" : "";
    const url = new URL(
      `/v2/screen/${screen.id}${pathSuffix}`,
      location.origin.toString(),
    );

    if (isVariantEnabled) url.searchParams.append("variant", "all");

    return url.toString();
  } else {
    return "about:blank";
  }
};

const Inspector: ComponentType = () => {
  const [config, setConfig] = useState<Config | null>(null);
  const [frameLoadedAt, setFrameLoadedAt] = useState(Date.now());

  useEffect(() => {
    fetch
      .get("/api/admin")
      .then((response) => JSON.parse(response.config))
      .then((config) => setConfig(config));
  }, []);

  const onScreenUpdated = (screenId, newConfig) => {
    if (config) {
      setConfig({
        ...config,
        screens: { ...config.screens, [screenId]: newConfig },
      });
    }
  };

  const { search } = useLocation();
  const urlParams = new URLSearchParams(search);
  const screenId = urlParams.get("id");

  const screen: ScreenWithId | null =
    config && screenId
      ? { id: screenId, config: config.screens[screenId] }
      : null;

  const [isSimulation, setIsSimulation] = useState(false);
  const [isVariantEnabled, setIsVariantEnabled] = useState(false);

  const iframeUrl = buildIframeUrl(screen, isSimulation, isVariantEnabled);

  const frameRef = useRef<HTMLIFrameElement>(null);

  const reloadFrame = () => frameRef.current?.contentWindow?.location.reload();

  const sendToFrame = (message: Message) => {
    const frameWindow = frameRef.current?.contentWindow;
    if (frameWindow) sendMessage(frameWindow, message);
  };

  const [zoom, setZoom] = useState(0.5);
  const adjustFrame = () => adjustScreenFrame(frameRef, isSimulation, zoom);
  useLayoutEffect(adjustFrame, [zoom]);

  return (
    <div className="inspector">
      <div className="inspector__controls">
        <h1>Inspector</h1>

        {config && (
          <>
            <ScreenSelector
              config={config}
              screen={screen}
              reloadFrame={reloadFrame}
              isSimulation={isSimulation}
              setIsSimulation={setIsSimulation}
              isVariantEnabled={isVariantEnabled}
              setIsVariantEnabled={setIsVariantEnabled}
            />

            {screen && (
              <>
                <ConfigControls
                  screen={screen}
                  onUpdated={(config) => onScreenUpdated(screen.id, config)}
                />
                <ViewControls
                  zoom={zoom}
                  setZoom={setZoom}
                  isSimulation={isSimulation}
                />
                <DataControls
                  // Reset when the iframe reloads, since the screen will no
                  // longer be aware of previously-sent inspector messages
                  key={frameLoadedAt}
                  isVariantEnabled={isVariantEnabled}
                  screen={screen}
                  sendToFrame={sendToFrame}
                />
                <AudioControls screen={screen} />
              </>
            )}
          </>
        )}
      </div>

      <div className="inspector__screen">
        <input disabled value={iframeUrl} />

        <iframe
          className={isSimulation ? "simulation" : undefined}
          name={INSPECTOR_FRAME_NAME}
          onLoad={() => {
            adjustFrame();
            setFrameLoadedAt(Date.now());
          }}
          ref={frameRef}
          src={iframeUrl}
        ></iframe>
      </div>
    </div>
  );
};

const ScreenSelector: ComponentType<{
  config: Config;
  screen: ScreenWithId | null;
  reloadFrame: () => void;
  isSimulation: boolean;
  setIsSimulation: (value: boolean) => void;
  isVariantEnabled: boolean;
  setIsVariantEnabled: (value: boolean) => void;
}> = ({
  config,
  screen,
  reloadFrame,
  isSimulation,
  setIsSimulation,
  isVariantEnabled,
  setIsVariantEnabled,
}) => {
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

  const selectEntries: [string, ScreenWithId[]][] = Object.entries(
    screensByType,
  ).sort(([typeA], [typeB]) => typeA.localeCompare(typeB));

  return (
    <fieldset>
      <legend>Screen</legend>

      <select
        value={screen?.id}
        onChange={(event) => navigateToScreen(event.target.value)}
      >
        <option></option>
        {selectEntries.map(([type, screens]) => (
          <optgroup label={type} key={type}>
            {screens.map(({ id, config: { name } }) => (
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
        Screenplay simulation
      </label>

      <label>
        <input
          type="checkbox"
          checked={isVariantEnabled}
          onChange={() => setIsVariantEnabled(!isVariantEnabled)}
        />
        Enable variant switcher
      </label>

      <button onClick={reloadFrame}>🔄 Reload Screen</button>
    </fieldset>
  );
};

const ConfigControls: ComponentType<{
  screen: ScreenWithId;
  onUpdated: (newConfig: Screen) => void;
}> = ({ screen, onUpdated }) => {
  const [editableConfig, setEditableConfig] = useState<Screen | null>(null);
  const [isRequestingReload, setIsRequestingReload] = useState(false);
  const dialogRef = useRef<HTMLDialogElement>(null);

  const closeDialog = () => {
    dialogRef.current?.close();
    setEditableConfig(null);
  };

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
            fetch
              .post("/api/admin/refresh", { screen_ids: [screen.id] })
              .then(() => alert("Scheduled a reload for this screen."))
              .finally(() => setIsRequestingReload(false));
          }}
        >
          Schedule Page Reload
        </button>
      </div>

      <dialog className="inspector__modal" ref={dialogRef}>
        <button
          className="inspector__modal__close-button"
          onClick={closeDialog}
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
            onUpdated={(newConfig) => {
              alert("Success. Allow 5 seconds for changes to propagate.");
              closeDialog();
              onUpdated(newConfig);
            }}
          />
        )}
      </dialog>
    </fieldset>
  );
};

const ViewControls: ComponentType<{
  zoom: number;
  setZoom: (zoom: number) => void;
  isSimulation: boolean;
}> = ({ zoom, setZoom, isSimulation }) => {
  const defaultZoom = isSimulation ? 1.0 : 0.5;
  useEffect(() => setZoom(defaultZoom), [defaultZoom, setZoom]);

  return (
    <fieldset>
      <legend>View</legend>

      <div>
        <button disabled={zoom <= 0.25} onClick={() => setZoom(zoom - 0.25)}>
          ➖
        </button>
        <button onClick={() => setZoom(zoom + 0.25)}>➕</button>
        <button onClick={() => setZoom(defaultZoom)}>Reset</button>
        <div>({zoom}x)</div>
      </div>
    </fieldset>
  );
};

const DataControls: ComponentType<{
  isVariantEnabled: boolean;
  screen: ScreenWithId;
  sendToFrame: (message: Message) => void;
}> = ({ isVariantEnabled, screen, sendToFrame }) => {
  const [dataTimestamp, setDataTimestamp] = useState<number | null>(null);
  const [dataSecondsOld, setDataSecondsOld] = useState<number | null>(null);
  const [isRefreshEnabled, setIsRefreshEnabled] = useState(true);
  const [variant, setVariant] = useState<string | null>(null);

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

  useEffect(() => {
    sendToFrame({ type: "set_data_variant", variant: variant });
  }, [variant]);

  return (
    <>
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

      {isVariantEnabled && (
        <fieldset>
          <legend>Variants</legend>

          <label>
            <input
              type="radio"
              name="variant"
              checked={variant === null}
              onChange={() => setVariant(null)}
            />
            Default
          </label>

          {(SCREEN_TYPE_VARIANTS[screen.config.app_id] ?? []).map((v) => (
            <label key={v}>
              <input
                type="radio"
                name="variant"
                checked={variant === v}
                onChange={() => setVariant(v)}
              />
              <code>{v}</code>
            </label>
          ))}
        </fieldset>
      )}
    </>
  );
};

const AudioControls: ComponentType<{ screen: ScreenWithId }> = ({ screen }) => {
  const [config, setConfig] = useState<AudioConfig | null | undefined>();
  // To bypass browser caching, we add a meaningless query param to the URL of
  // the <audio> element, based on the timestamp the Play button was clicked.
  const [playingAt, setPlayingAt] = useState<Date | null>(null);
  const [ssml, setSSML] = useState<string | null>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(
    () => (ssml ? dialogRef.current?.showModal() : dialogRef.current?.close()),
    [dialogRef, ssml],
  );

  useReceiveMessage((message) => {
    if (message.type == "audio_config") setConfig(message.config);
  });

  const audioPath = AUDIO_SCREEN_TYPES.has(screen.config.app_id)
    ? `/v2/audio/${screen.id}`
    : null;

  return (
    <fieldset>
      <legend>Audio</legend>

      {audioPath ? (
        <>
          <div>
            <button
              onClick={() => {
                setSSML("Loading...");
                fetch.text(`${audioPath}/debug`).then((text) => setSSML(text));
              }}
            >
              Show SSML
            </button>

            {playingAt ? (
              <button onClick={() => setPlayingAt(null)}>⏹️ Stop Audio</button>
            ) : (
              <button onClick={() => setPlayingAt(new Date())}>
                ▶️ Play Audio
              </button>
            )}
          </div>

          <dialog className="inspector__modal" ref={dialogRef}>
            <button
              className="inspector__modal__close-button"
              onClick={() => setSSML(null)}
            >
              × Close
            </button>
            <div className="inspector__modal__ssml">{ssml}</div>
          </dialog>

          {playingAt && (
            <audio
              autoPlay={true}
              onEnded={() => setPlayingAt(null)}
              src={`${audioPath}/readout.mp3?at=${playingAt.getTime()}`}
            />
          )}

          {config !== undefined && (
            <div>
              {config ? (
                <span>
                  🔈 Plays every <b>{config.readoutIntervalMinutes}</b> minutes
                  (offset <b>{config.intervalOffsetSeconds}</b> seconds)
                </span>
              ) : (
                "🔇 No periodic audio readout"
              )}
            </div>
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
    let style = doc.getElementById("inspector-injected-style");

    if (!style) {
      style = doc.createElement("style");
      style.id = "inspector-injected-style";
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
