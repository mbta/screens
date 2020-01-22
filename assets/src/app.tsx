declare function require(name: string): string;
// tslint:disable-next-line
require("../css/app.scss");

import "phoenix_html";
import React, { useEffect, useState } from "react";
import ReactDOM from "react-dom";

function App(): JSX.Element {
  const [time, setTime] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    setTime(new Date().toLocaleTimeString());

    const interval = setInterval(() => {
      setTime(new Date().toLocaleTimeString());
    }, 10000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div>
      <div className="timestamp">{time}</div>
      <div className="logo">
        <img src="images/logo.svg" />
      </div>
    </div>
  );
}

ReactDOM.render(<App />, document.getElementById("app"));
