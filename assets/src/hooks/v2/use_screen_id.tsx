import { type ReactNode, createContext, useContext } from "react";

const ScreenIDContext = createContext<string>("");

export const ScreenIDProvider = ({
  id,
  children,
}: {
  id: string;
  children: ReactNode;
}) => (
  <ScreenIDContext.Provider value={id}>{children}</ScreenIDContext.Provider>
);

export const useScreenID = (): string => useContext(ScreenIDContext);
