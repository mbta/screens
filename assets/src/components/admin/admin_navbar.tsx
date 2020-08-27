import React from "react";
import { Link } from "react-router-dom";

const AdminNavbar = (): JSX.Element => {
  return (
    <div className="admin-navbar">
      <Link to="/">
        <button>Admin Form</button>
      </Link>
      <Link to="/all-screens-table">
        <button>All Screens Table</button>
      </Link>
      <Link to="/bus-screens-table">
        <button>Bus Screens Table</button>
      </Link>
      <Link to="/gl_single-screens-table">
        <button>GL Single Screens Table</button>
      </Link>
      <Link to="/gl_double-screens-table">
        <button>GL Double Screens Table</button>
      </Link>
      <Link to="/solari-screens-table">
        <button>Solari Screens Table</button>
      </Link>
    </div>
  );
};

export default AdminNavbar;
