const doSubmit = async (path, data) => {
  try {
    const csrfToken = document.head.querySelector("[name~=csrf-token][content]")
      .content;
    const result = await fetch(path, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-csrf-token": csrfToken,
      },
      credentials: "include",
      body: JSON.stringify(data),
    });
    const json = await result.json();
    return json;
  } catch (err) {
    alert("An error occurred.");
    throw err;
  }
};

export { doSubmit };
