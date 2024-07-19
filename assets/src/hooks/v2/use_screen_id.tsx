import React, { useContext } from "react";

const ScreenIDContext = React.createContext<string>("");

export const ScreenIDProvider = ({
  id,
  children,
}: {
  id: string;
  children: React.ReactNode;
}) => (
  <ScreenIDContext.Provider value={id}>{children}</ScreenIDContext.Provider>
);

export const useScreenID = (): string => useContext(ScreenIDContext);
