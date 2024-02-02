import BlueLine from '../../static/images/svgr_bundled/pills/blue-line.svg'
import BL from '../../static/images/svgr_bundled/pills/bl.svg'
import GreenLine from '../../static/images/svgr_bundled/pills/green-line.svg'
import GL from '../../static/images/svgr_bundled/pills/gl.svg'
import OrangeLine from '../../static/images/svgr_bundled/pills/orange-line.svg'
import OL from '../../static/images/svgr_bundled/pills/ol.svg'
import RedLine from '../../static/images/svgr_bundled/pills/red-line.svg'
import RL from '../../static/images/svgr_bundled/pills/rl.svg'
import CommuterRail from '../../static/images/svgr_bundled/pills/commuter-rail.svg'
// GL Branches
import GLB from '../../static/images/svgr_bundled/pills/gl-b.svg'
import GLC from '../../static/images/svgr_bundled/pills/gl-c.svg'
import GLD from '../../static/images/svgr_bundled/pills/gl-d.svg'
import GLE from '../../static/images/svgr_bundled/pills/gl-e.svg'
import GreenLineB from '../../static/images/svgr_bundled/pills/green-line-b.svg'
import GreenLineC from '../../static/images/svgr_bundled/pills/green-line-c.svg'
import GreenLineD from '../../static/images/svgr_bundled/pills/green-line-d.svg'
import GreenLineE from '../../static/images/svgr_bundled/pills/green-line-e.svg'
import GreenBCircle from '../../static/images/svgr_bundled/pills/green-b-circle.svg'
import GreenCCircle from '../../static/images/svgr_bundled/pills/green-c-circle.svg'
import GreenDCircle from '../../static/images/svgr_bundled/pills/green-d-circle.svg'
import GreenECircle from '../../static/images/svgr_bundled/pills/green-e-circle.svg'
// Destination pills
import BLBowdoin from '../../static/images/svgr_bundled/pills/bl-bowdoin.svg'
import BLWonderland from '../../static/images/svgr_bundled/pills/bl-wonderland.svg'
import GLCopleyWest from '../../static/images/svgr_bundled/pills/gl-copley-west.svg'
import GLGovtCenter from '../../static/images/svgr_bundled/pills/gl-govt-center.svg'
import GLNorthStationNorth from '../../static/images/svgr_bundled/pills/gl-north-station-north.svg'
import GLBBostonCollege from '../../static/images/svgr_bundled/pills/glb-boston-college.svg'
import GLCClevelandCircle from '../../static/images/svgr_bundled/pills/glc-cleveland-cir.svg'
import GLDRiverside from '../../static/images/svgr_bundled/pills/gld-riverside.svg'
import GLDUnionSq from '../../static/images/svgr_bundled/pills/gld-union-sq.svg'
import GLEHeathSt from '../../static/images/svgr_bundled/pills/gle-heath-st.svg'
import GLEMedfordTufts from '../../static/images/svgr_bundled/pills/gle-medford-tufts.svg'
import OLForestHills from '../../static/images/svgr_bundled/pills/ol-forest-hills.svg'
import OLOakGrove from '../../static/images/svgr_bundled/pills/ol-oak-grove.svg'
import RLAlewife from '../../static/images/svgr_bundled/pills/rl-alewife.svg'
import RLAshmont from '../../static/images/svgr_bundled/pills/rl-ashmont.svg'
import RLBraintree from '../../static/images/svgr_bundled/pills/rl-braintree.svg'

export const STRING_TO_SVG: {[key: string]: any} = {
  "blue-line": BlueLine,
  "bl": BL,
  "green-line": GreenLine,
  "gl": GL,
  "orange-line": OrangeLine,
  "ol": OL,
  "red-line": RedLine,
  "rl": RL,
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
  "rl-braintree": RLBraintree
};

const STRING_TO_COLOR: {[key: string]: string} = {
  "blue": "#003DA5",
  "orange": "#ED8B00",
  "red": "#DA291C",
  "green": "#00843D",
  "purple": "#80276C",
}

export const getHexColor = (color: string) => STRING_TO_COLOR[color]
