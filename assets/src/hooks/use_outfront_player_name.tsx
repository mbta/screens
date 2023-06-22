import { useEffect, useState } from "react";

const useOutfrontTags = () => {
  const [tags, setTags] = useState(null);

  let mraid;

  try {
    mraid = parent?.parent?.mraid;
  } catch (_) {}

  if (mraid) {
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
  }

  return tags;
};

const useOutfrontPlayerName = () => {
  const tags = useOutfrontTags();
  if (tags !== null) {
    const playerName =
      tags.find(({ name }) => name === "player_name")?.value?.[0] ?? null;
    return playerName;
  } else {
    return null;
  }
};

export default useOutfrontPlayerName;
