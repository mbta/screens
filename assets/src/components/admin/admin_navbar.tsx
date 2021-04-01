import React from "react";
import { Link } from "react-router-dom";

const AdminNavbar = (): JSX.Element => {
  return (
    <div className="admin-navbar">
      <Link to="/all-screens">
        <button>All Screens Table</button>
      </Link>
      <Link to="/bus-screens">
        <button>Bus Screens Table</button>
      </Link>
      <Link to="/gl_single-screens">
        <button>GL Single Screens Table</button>
      </Link>
      <Link to="/gl_double-screens">
        <button>GL Double Screens Table</button>
      </Link>
      <Link to="/solari-screens">
        <button>Solari Screens Table</button>
      </Link>
      <Link to="/dup-screens">
        <button>DUP Screens Table</button>
      </Link>
      <Link to="/bus-shelter-screens">
        <button>Bus Shelter Screens Table</button>
      </Link>
      <Link to="/json-editor">
        <button>JSON Editor</button>
      </Link>
      <Link to="/image-manager">
        <button>Image Manager</button>
      </Link>
      <Link to="/devops">
        <button>Devops</button>
      </Link>
    </div>
  );
};

export default AdminNavbar;
