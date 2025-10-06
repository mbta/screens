import { useEffect, useState } from "react";

import { fetch, type ScreenWithId, Config } from "Util/admin";

const Table = () => {
  const [screens, setScreens] = useState<ScreenWithId[] | null>(null);

  // Fetch config on page load
  const fetchConfig = async () => {
    const { config }: { config: Config } = await fetch.get("/api/admin");
    setScreens(
      Object.entries(config.screens).map(([id, config]) => ({ id, config })),
    );
  };

  useEffect(() => {
    fetchConfig();
    return;
  }, []);

  return <table></table>;
};

export default Table;
