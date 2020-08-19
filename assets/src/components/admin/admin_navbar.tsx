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
    </div>
  );
};

export default AdminNavbar;
