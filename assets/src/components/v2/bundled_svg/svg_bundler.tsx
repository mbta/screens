import React, { ComponentType } from "react";

// import AlertIcon from 'react-svg-loader!../../../../static/images/test/alert-test.svg';

// import { ReactComponent as AlertIcon } from '../../../../static/images/test/alert-test.svg'
import AlertIcon from '../../../../static/images/test/alert-test.svg'

interface Props {
  className?: string;
  svgString?: string;
  colorHex?: string;
}

const SvgBundler: ComponentType<Props> = ({}) => (
  <AlertIcon />
);

export default SvgBundler;
