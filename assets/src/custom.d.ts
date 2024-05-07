// Allow importing and using any SVG, PNG, or JPG file as though it were a React component.

declare module "*.svg" {
  const content: React.FunctionComponent<React.SVGAttributes<SVGElement>>;
  export default content;
}

declare module "*.png";
declare module "*.jpg";
