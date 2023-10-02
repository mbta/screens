// const API_HOST = "https://screens.mbta.com";

// const screenDataUrl = (playerName) => `${API_HOST}/v2/screen/${playerName}/triptych`;
// const logErrorUrl = () => `${API_HOST}/v2/api/logging/log_frontend_error`;

// const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// const getMRAID = async () => {
//   const mraid = parent?.parent?.mraid ?? false;
//   if (mraid) {
//     return mraid
//   } else {
//     await sleep(5);
//     return getMRAID();
//   }
// };

// const getTags = (mraid) => {
//   try {
//     return JSON.parse(mraid.getTags()).tags;
//   } catch (err) {
//     showNoData();
//     throw err;
//   }
// };

// const arrayConfigurationToTriptychPane = (arrayConfiguration) => {
//   switch (arrayConfiguration) {
//     case "Triple_Left":
//       return "left";
//     case "Triple_Middle":
//       return "middle";
//     case "Triple_Right":
//       return "right";
//     default:
//       showNoData();
//       throw new Error(`Couldn't parse Array_configuration value: ${arrayConfiguration}`);
//   }
// };

// const getOutfrontData = async () => {
//   const mraid = await getMRAID();
//   const tags = getTags(mraid);

//   const arrayConfiguration = tags.find(({ name }) => name === "Array_configuration")?.value?.[0] ?? null;
//   const triptychPane = arrayConfigurationToTriptychPane(arrayConfiguration);

//   return {mraid};
// }

// const getTriptychPane = async () => {
//   const tags = await getTags();
//   if (tags !== null) {
//     const arrayConfiguration =
//       tags.find(({ name }) => name === "Array_configuration")?.value?.[0] ??
//       null;
//     pane = arrayConfigurationToTriptychPane(arrayConfiguration);
//   }

//   return pane;
// };

// while (!mraid())

// class TriptychApp extends HTMLDivElement {
//   constructor() {
//     super();
//   }


// }

// const showNoData = () => {
//   // TODO
// };

function setTemplate(id) {
  let template = document.getElementById(id);
  let templateContent = template.content;
  document.body.innerHTML = '';
  document.body.appendChild(templateContent);
}
const getMRAID = async () => {
  const mraid = parent?.parent?.mraid ?? false;
  if (mraid) {
    return mraid;
  } else {
    await sleep(5);
    return getMRAID();
  }
};

const getTags = (mraid) => {
  try {
    return JSON.parse(mraid.getTags()).tags;
  } catch (err) {
    // showNoData();
    setTemplate('error')
    throw err;
  }
};

const arrayConfigurationToTriptychPane = (arrayConfiguration) => {
  switch (arrayConfiguration) {
    case "Triple_Left":
      return "left";
    case "Triple_Middle":
      return "middle";
    case "Triple_Right":
      return "right";
    default:
      // showNoData();
      setTemplate('error')
      throw new Error(`Couldn't parse Array_configuration value: ${arrayConfiguration}`);
  }
};

const getOutfrontData = async () => {
  const mraid = await getMRAID();
  const tags = getTags(mraid);

  const arrayConfiguration = tags.find(({ name }) => name === "Array_configuration")?.value?.[0] ?? null;
  const triptychPane = arrayConfigurationToTriptychPane(arrayConfiguration);

  return { triptychPane, stationName };
}

async function fetchData(playerId) {
  try {
    const { triptychPane } = getOutfrontData();
    const result = await fetch(`https://screens.mbta.com/v2/api/screen/${playerId}/triptych?is_real_screen=true&pane=${triptychPane}`);
    const json = await result.json();

    if (json.data == null) {
      setTemplate('error')
    } else {
      // pick the template
    }
  } catch (err) {
    setTemplate('error')
  }

};

customElements.define(
  "psa-set",
  class extends HTMLElement {
    constructor() {
      super();
      let template = document.getElementById("psa-set");
      let templateContent = template.content;
      const { triptychPane } = getOutfrontData();


      let img = document.createElement('img');
      const path = this.getAttribute("path")
      img.setAttribute("src", path)

      document.body.innerHTML = '';
      document.body.appendChild(templateContent);
    }


  },
);



