import React, { ComponentType, useEffect, useState } from "react";
import makePersistent, { WrappedComponentProps } from "./persistent_wrapper";

interface PageRendererProps {
  page: any;
  pageIndex: number;
  numPages: number;
}

interface Props extends WrappedComponentProps {
  PageRenderer: ComponentType<PageRendererProps>;
  pages: any[];
}

const Carousel: ComponentType<Props> = ({ PageRenderer, pages, onFinish, lastUpdate }) => {
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
 * Call this function on a `PageRenderer` component to wrap it in a persistent component that
 * expects a `pages` prop containing an array of data, and passes one element of the array at a time to
 * `PageRenderer`.
 *
 * Consider extending the `PageRendererProps` type exported by this module when
 * defining your `PageRenderer`'s props.
 *
 * Example:
 * ```tsx
 * const Image = ({ url }) => <img src={url} />;
 * const PersistentImageCarousel = makePersistentCarousel(Image);
 *
 * // in some other component's render...
 * const pages = [{url: "/psa.png"}, {url: "/squirrel.jpg"}, {url: "/survey.png"}];
 * return (
 *   <div>
 *     <PersistentImageCarousel pages={pages} />
 *   </div>
 * );
 * ```
 */
const makePersistentCarousel =
  (Component: ComponentType<PageRendererProps>) =>
    ({ ...data }) =>
      <PersistentCarousel {...data} PageRenderer={Component} />;

export default makePersistentCarousel;
export { PageRendererProps };
