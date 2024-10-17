import initSentry from "Util/sentry";
initSentry("elevator");

import initFullstory from "Util/fullstory";
initFullstory();

require("../../../css/elevator_v2.scss");

import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import NormalScreen from "Components/v2/elevator/normal_screen";
import Placeholder from "Components/v2/placeholder";
import EvergreenContent from "Components/v2/evergreen_content";
import ScreenPage from "Components/v2/screen_page";
import { MappingContext } from "Components/v2/widget";
import MultiScreenPage from "Components/v2/multi_screen_page";

const TYPE_TO_COMPONENT = {
  normal: NormalScreen,
  placeholder: Placeholder,
  evergreen_content: EvergreenContent,
};

const App = (): JSX.Element => {
  return (
    <Router>
      <Routes>
        <Route
          path="/v2/screen/elevator_v2"
          element={<MultiScreenPage components={TYPE_TO_COMPONENT} />}
        />

        <Route
          path="/v2/screen/:id"
          element={
            <MappingContext.Provider value={TYPE_TO_COMPONENT}>
              <ScreenPage />
            </MappingContext.Provider>
          }
        />
      </Routes>
    </Router>
  );
};

const container = document.getElementById("app");
const root = createRoot(container!);
root.render(<App />);
