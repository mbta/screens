import BlueLine from "Images/pills/blue-line.svg";
import BL from "Images/pills/bl.svg";
import GreenLine from "Images/pills/green-line.svg";
import GL from "Images/pills/gl.svg";
import OrangeLine from "Images/pills/orange-line.svg";
import OL from "Images/pills/ol.svg";
import RedLine from "Images/pills/red-line.svg";
import RL from "Images/pills/rl.svg";
import CommuterRail from "Images/pills/commuter-rail.svg";
// GL Branches
import GLB from "Images/pills/gl-b.svg";
import GLC from "Images/pills/gl-c.svg";
import GLD from "Images/pills/gl-d.svg";
import GLE from "Images/pills/gl-e.svg";
import GreenLineB from "Images/pills/green-line-b.svg";
import GreenLineC from "Images/pills/green-line-c.svg";
import GreenLineD from "Images/pills/green-line-d.svg";
import GreenLineE from "Images/pills/green-line-e.svg";
import GreenBCircle from "Images/pills/green-b-circle.svg";
import GreenCCircle from "Images/pills/green-c-circle.svg";
import GreenDCircle from "Images/pills/green-d-circle.svg";
import GreenECircle from "Images/pills/green-e-circle.svg";
// Destination pills
import BLBowdoin from "Images/pills/bl-bowdoin.svg";
import BLWonderland from "Images/pills/bl-wonderland.svg";
import GLCopleyWest from "Images/pills/gl-copley-west.svg";
import GLGovtCenter from "Images/pills/gl-govt-center.svg";
import GLNorthStationNorth from "Images/pills/gl-north-station-north.svg";
import GLBBostonCollege from "Images/pills/glb-boston-college.svg";
import GLCClevelandCircle from "Images/pills/glc-cleveland-cir.svg";
import GLDRiverside from "Images/pills/gld-riverside.svg";
import GLDUnionSq from "Images/pills/gld-union-sq.svg";
import GLEHeathSt from "Images/pills/gle-heath-st.svg";
import GLEMedfordTufts from "Images/pills/gle-medford-tufts.svg";
import OLForestHills from "Images/pills/ol-forest-hills.svg";
import OLOakGrove from "Images/pills/ol-oak-grove.svg";
import RLAlewife from "Images/pills/rl-alewife.svg";
import RLAshmont from "Images/pills/rl-ashmont.svg";
import RLBraintree from "Images/pills/rl-braintree.svg";

export const STRING_TO_SVG: { [key: string]: any } = {
  "blue-line": BlueLine,
  bl: BL,
  "green-line": GreenLine,
  gl: GL,
  "orange-line": OrangeLine,
  ol: OL,
  "red-line": RedLine,
  rl: RL,
  "commuter-rail": CommuterRail,
  // Green line branches
  "gl-b": GLB,
  "gl-c": GLC,
  "gl-d": GLD,
  "gl-e": GLE,
  "green-line-b": GreenLineB,
  "green-line-c": GreenLineC,
  "green-line-d": GreenLineD,
  "green-line-e": GreenLineE,
  "green-b-circle": GreenBCircle,
  "green-c-circle": GreenCCircle,
  "green-d-circle": GreenDCircle,
  "green-e-circle": GreenECircle,
  // Pills with destinations
  "bl-bowdoin": BLBowdoin,
  "bl-wonderland": BLWonderland,
  "gl-copley-west": GLCopleyWest,
  "gl-govt-center": GLGovtCenter,
  "gl-north-station-north": GLNorthStationNorth,
  "glb-boston-college": GLBBostonCollege,
  "glc-cleveland-cir": GLCClevelandCircle,
  "gld-riverside": GLDRiverside,
  "gld-union-sq": GLDUnionSq,
  "gle-heath-st": GLEHeathSt,
  "gle-medford-tufts": GLEMedfordTufts,
  "ol-forest-hills": OLForestHills,
  "ol-oak-grove": OLOakGrove,
  "rl-alewife": RLAlewife,
  "rl-ashmont": RLAshmont,
  "rl-braintree": RLBraintree,
};

const STRING_TO_COLOR: { [key: string]: string } = {
  blue: "#003DA5",
  orange: "#ED8B00",
  red: "#DA291C",
  green: "#00843D",
  purple: "#80276C",
  cape_blue: "#006595"
};

export const getHexColor = (color: string) => STRING_TO_COLOR[color];
