import { useEffect, useState } from "react";
import _ from "lodash";

const useOutfrontTags = () => {
  const [tags, setTags] = useState(null);

  useEffect(() => {
    if (parent && parent.parent && parent.parent.mraid) {
      try {
        const rawTags = parent.parent.mraid.getTags();
        setTags(JSON.parse(rawTags).tags);
      } catch (err) {
        setTags(null);
      }
    }
  }, []);

  return tags;
};

const useOutfrontStation = () => {
  const tags = useOutfrontTags();
  if (tags !== null) {
    const station = _.find(tags, ({ name }) => name === "Station").value;
    return station;
  } else {
    return null;
  }
};

export default useOutfrontTags;
export { useOutfrontStation };
