import BlueLine from '../../static/images/svgr_bundled/pills/blue-line.svg'
import BL from '../../static/images/svgr_bundled/pills/bl.svg'
import OrangeLine from '../../static/images/svgr_bundled/pills/orange-line.svg'
import OL from '../../static/images/svgr_bundled/pills/ol.svg'
import RedLine from '../../static/images/svgr_bundled/pills/red-line.svg'
import RL from '../../static/images/svgr_bundled/pills/rl.svg'
import GreenLine from '../../static/images/svgr_bundled/pills/green-line.svg'
import GL from '../../static/images/svgr_bundled/pills/gl.svg'
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
import CommuterRail from '../../static/images/svgr_bundled/pills/commuter-rail.svg'

export const STRING_TO_SVG: {[key: string]: any} = {
  "blue-line": BlueLine,
  "bl": BL,
  "orange-line": OrangeLine,
  "ol": OL,
  "red-line": RedLine,
  "rl": RL,
  "green-line": GreenLine,
  "gl": GL,
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
  "commuter-rail": CommuterRail,
};

const STRING_TO_COLOR: {[key: string]: string} = {
  "blue": "#003DA5",
  "orange": "#ED8B00",
  "red": "#DA291C",
  "green": "#00843D",
  "purple": "#80276C",
}

export const getHexColor = (color: string) => STRING_TO_COLOR[color]
