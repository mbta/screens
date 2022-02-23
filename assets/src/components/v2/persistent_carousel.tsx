import React, { ComponentType, useEffect, useState } from "react";
import makePersistent from "./persistent_wrapper";

interface Props {
  PageRenderer: ComponentType<any>;
  pages: any[];
  onFinish: () => void;
  lastUpdate: number | null;
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

const PersistentCarousel = makePersistent(Carousel);

/**
 * Call this function on a `PageRenderer` component to wrap it in a persistent component that
 * expects a `pages` prop containing an array of data, and passes one element of the array at a time to
 * `PageRenderer`.
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
  (Component) =>
    ({ ...data }) =>
      <PersistentCarousel {...data} PageRenderer={Component} />;

export default makePersistentCarousel;
