import React, { ComponentType, ReactNode, useEffect, useState } from "react";
import makePersistent, { WrappedComponentProps } from "./persistent_wrapper";

interface PageRendererProps<T> {
  page: T;
  pageIndex: number;
  numPages: number;
}

interface Props<T> extends WrappedComponentProps {
  PageRenderer: ComponentType<PageRendererProps<T>>;
  pages: T[];
}

const Carousel = <T,>({ PageRenderer, pages, onFinish, lastUpdate }: Props<T>): ReactNode => {
  const [isFirstRender, setIsFirstRender] = useState(true);
  const [pageIndex, setPageIndex] = useState(0);

  useEffect(() => {
    if (lastUpdate != null) {
      if (isFirstRender) {
        setIsFirstRender(false);
      } else {
        setPageIndex((i) => i + 1);
      }
    }
  }, [lastUpdate]);

  useEffect(() => {
    if (pageIndex === pages.length - 1) {
      onFinish();
    }
  }, [pageIndex]);

  return (
    <PageRenderer page={pages[pageIndex]} pageIndex={pageIndex} numPages={pages.length} />
  );
}

const PersistentCarousel = makePersistent(Carousel as ComponentType<WrappedComponentProps>);

/**
 * Call this function on some `PageRenderer` component to wrap it in a persistent component that
 * expects a `pages` prop containing an array of data, and will pass one element of the array at a time to
 * `PageRenderer`.
 *
 * Consider using the `PageRendererProps` type exported by this module when
 * defining your `PageRenderer`'s prop types.
 *
 * `PageRenderer` must expect the following props (and no other props):
 * - `page`: The data that the component needs to render. You supply the type for this value.
 * - `pageIndex`: The index of the current page being shown.
 * - `numPages`: The length of the current `pages` array.
 *
 * Example:
 * ```tsx
 * //// in persistent_image_carousel.tsx
 * // Define a type for the data our component requires in order to render one page of content.
 * interface ImageData {
 *   url: string;
 *   caption: string;
 * }
 *
 * // Pass as a parameter to PageRendererProps to get the type {page: ImageData, pageIndex: number, numPages: number}
 * type Props = PageRendererProps<ImageData>;
 *
 * // This is our `PageRenderer` component.
 * const Image: ComponentType<Props> = ({ page: {url, caption}, pageIndex, numPages }) => (
 *   <div>
 *     <figure>
 *       <img src={url} />
 *       <figcaption>{caption}</figcaption>
 *     </figure>
 *     <div>Page {pageIndex + 1} of {numPages}</div>
 *   </div>
 * );
 *
 * export default makePersistentCarousel(Image);
 *
 * //// in some other module...
 * import PersistentImageCarousel from "persistent_image_carousel";
 *
 * const Container = ({}) => {
 *   const pages = [
 *     {url: "/psa.png", caption: "It's a PSA!"},
 *     {url: "/squirrel.jpg", caption: "Beware."},
 *     {url: "/survey.png", caption: "Penny for your thoughts?"}
 *   ];
 *
 *   return (
 *     <div>
 *       <PersistentImageCarousel pages={pages} />
 *       <OtherStuff  />
 *     </div>
 *   );
 * };
 * ```
 */
const makePersistentCarousel =
  <T,>(Component: ComponentType<PageRendererProps<T>>) =>
    ({ ...data }) =>
      <PersistentCarousel {...data} PageRenderer={Component} />;

export default makePersistentCarousel;
export { PageRendererProps };
