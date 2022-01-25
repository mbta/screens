import React, { ComponentType, useEffect, useState } from "react";

type Page = ListPage | DetailPage;

interface DetailPage {
  header_text: string;
  icons: Icon[];
  elevator_closure: Closure;
}

interface ListPage {
  stations: Station[];
}

interface Station {
  name: string;
  icons: Icon[];
  elevator_closures: Closure[];
  is_at_home_stop: boolean;
}

interface Closure {
  elevator_name: string;
  elevator_id: string;
  timeframe: {
    happening_now: boolean;
    active_period: ActivePeriod[];
  };
}

interface ActivePeriod {
  start: string;
  end: string;
}

type Icon = "orange" | "red" | "green" | "blue" | "silver" | "rail" | "bus";

interface Props {
  pages: Page[];
  lastUpdated: number;
  onFinished: Function;
}

const ElevatorStatus: ComponentType<Props> = ({
  pages,
  lastUpdated,
  onFinished,
}) => {
  const [isFirstRender, setIsFirstRender] = useState(true);
  const [pageIndex, setPageIndex] = useState(0);

  useEffect(() => {
    if (isFirstRender) {
      setIsFirstRender(false);
    } else {
      setPageIndex((i) => i + 1);
    }
  }, [lastUpdated]);

  useEffect(() => {
    if (pageIndex === pages.length - 1) {
      onFinished();
    }
  }, [pageIndex]);

  const page = pages[pageIndex];
  if (page == null) return null;
  if (instanceOfDetailPage(page)) {
    return <DetailPageComponent detailPage={page as DetailPage} />;
  } else if (instanceOfListPage(page)) {
    return <ListPageComponent listPage={page as ListPage} />;
  }
  return null;
};

const instanceOfDetailPage = (page: Page): page is DetailPage => {
  return (page as DetailPage).header_text !== undefined;
};

const instanceOfListPage = (page: Page): page is ListPage => {
  return (page as ListPage).stations !== undefined;
};

interface DetailPageProps {
  detailPage: DetailPage;
}

const DetailPageComponent: ComponentType<DetailPageProps> = ({
  detailPage,
}) => {
  return null;
};

interface ListPageProps {
  listPage: ListPage;
}

const ListPageComponent: ComponentType<ListPageProps> = ({ listPage }) => {
  return null;
};

export default ElevatorStatus;
