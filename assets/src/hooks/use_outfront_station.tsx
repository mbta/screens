import { useEffect, useState } from "react";

const useOutfrontTags = () => {
  const [tags, setTags] = useState(null);

  useEffect(() => {
    if (parent?.parent?.mraid ?? false) {
      try {
        const rawTags = parent.parent.mraid.getTags();
        setTags(JSON.parse(rawTags).tags);
      } catch (err) {
        setTags(null);
      }
    }
  }, [parent?.parent?.mraid]);

  return tags;
};

const useOutfrontStation = () => {
  const tags = useOutfrontTags();
  if (tags !== null) {
    const station =
      tags.find(({ name }) => name === "Station")?.value?.[0] ?? null;
    return station;
  } else {
    return null;
  }
};

export default useOutfrontStation;
