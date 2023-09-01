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
      <Link to="/solari-large-screens">
        <button>Solari Large Screens Table</button>
      </Link>
      <Link to="/dup-screens">
        <button>DUP Screens Table</button>
      </Link>
      <Link to="/dup-v2-screens">
        <button>DUP V2 Screens Table</button>
      </Link>
      <Link to="/bus-shelter-screens">
        <button>Bus Shelter Screens Table</button>
      </Link>
      <Link to="/bus-eink-v2-screens">
        <button>Bus Eink V2 Screens Table</button>
      </Link>
      <Link to="/gl-eink-v2-screens">
        <button>GL Eink V2 Screens Table</button>
      </Link>
      <Link to="/solari-v2-screens">
        <button>Solari V2 Screens Table</button>
      </Link>
      <Link to="/solari-large-v2-screens">
        <button>Solari Large V2 Screens Table</button>
      </Link>
      <Link to="/bus-shelter-v2-screens">
        <button>Bus Shelter V2 Screens Table</button>
      </Link>
      <Link to="/pre-fare-v2-screens">
        <button>Pre-Fare V2 Screens Table</button>
      </Link>
      <Link to="/triptych-v2-screens">
        <button>Triptych V2 Screens Table</button>
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
