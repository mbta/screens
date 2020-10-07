import React, { useCallback, useEffect, useState } from "react";
import { useDropzone } from "react-dropzone";
import _ from "lodash";

interface FileWithPreview extends File {
  preview: string;
}

const fetchWithCsrf = (resource: RequestInfo, init: RequestInit = {}) => {
  const csrfToken = document.head.querySelector("[name~=csrf-token][content]")
    .content;
  return fetch(resource, {
    ...init,
    headers: { ...(init?.headers || {}), "x-csrf-token": csrfToken },
    credentials: "include",
  });
};

const fetchImageFilenames = async () => {
  const response = await fetchWithCsrf("/api/admin/image_filenames");
  const { image_filenames: imageFilenames } = await response.json();
  return _.sortBy(imageFilenames);
};

const ImageFilenameSelect = ({ options, onChange }): JSX.Element => {
  const handleChange = (e) => {
    onChange(e.target.value);
  };

  return (
    <select onChange={handleChange} defaultValue={undefined}>
      <option value={undefined}></option>
      {options.map((opt) => (
        <option value={opt} key={opt}>
          {opt}
        </option>
      ))}
    </select>
  );
};

const ImageThumbnail = ({ src, fullSize = false }): JSX.Element => (
  <div className="admin-image-manager__thumbnail-container">
    <div
      className={`admin-image-manager__thumbnail${
        fullSize ? "--full-size" : ""
      }`}
    >
      <div className="admin-image-manager__thumbnail-inner">
        <img className="admin-image-manager__thumbnail-image" src={src} />
      </div>
    </div>
  </div>
);

const S3ImageThumbnail = ({ filename }): JSX.Element => (
  <ImageThumbnail src={`/api/admin/image/${filename}`} fullSize />
);

const ImageManagerContainer = ({}): JSX.Element => {
  const [imageFilenames, setImageFilenames] = useState<string[]>([]);

  const loadState = async () => {
    setImageFilenames(await fetchImageFilenames());
  };

  useEffect(() => {
    loadState();
    return;
  }, []);

  return imageFilenames.length > 0 ? (
    <ImageManager imageFilenames={imageFilenames} />
  ) : (
    <div>Loading...</div>
  );
};

const ImageUpload = ({}): JSX.Element => {
  const [stagedImageUpload, setStagedImageUpload] = useState<FileWithPreview>(
    null
  );
  const [isUploading, setIsUploading] = useState(false);

  const handleClickUpload = async () => {
    setIsUploading(true);

    const formData = new FormData();
    formData.append("image", stagedImageUpload, stagedImageUpload.name);

    try {
      const response = await fetchWithCsrf("/api/admin/image", {
        method: "POST",
        body: formData,
      });

      const result = await response.json();
      if (result.success) {
        alert(`Success. Image has been uploaded as "${result.uploaded_name}".`);
        location.reload();
      } else {
        throw new Error();
      }
    } catch (e) {
      alert("Upload failed.");
      setIsUploading(false);
    }
  };

  const onDrop = useCallback(
    ([acceptedFile]) => {
      if (!!acceptedFile) {
        const fileWithPreview = Object.assign(acceptedFile, {
          preview: URL.createObjectURL(acceptedFile),
        });
        setStagedImageUpload(fileWithPreview);
      } else {
        alert("That file is too large; please try one under 20MB.");
      }
    },
    [setStagedImageUpload]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: ["image/png", "image/gif", "image/svg+xml"],
    multiple: false,
    maxSize: 20000000,
  });

  return (
    <>
      <div {...getRootProps({ className: "admin-image-manager__dropzone" })}>
        <input {...getInputProps()} />
        {isDragActive ? (
          <p>Drop your image here.</p>
        ) : (
          <p>Drag and drop, or click to select an image.</p>
        )}
        <p>
          <strong>
            PNG, GIF, or XML only. 20MB max. Make sure your image has the name
            you want to use!
          </strong>
        </p>
      </div>
      {stagedImageUpload != null && (
        <ImageThumbnail src={stagedImageUpload.preview} />
      )}
      <button
        className="admin-image-manager__upload-button"
        disabled={stagedImageUpload == null || isUploading}
        onClick={handleClickUpload}
      >
        {isUploading ? "Uploading..." : "Upload"}
      </button>
    </>
  );
};

const ImageManager = ({ imageFilenames }): JSX.Element => {
  const [selectedFilename, setSelectedFilename] = useState(undefined);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleClickDelete = async () => {
    if (confirm(`Permanently delete "${selectedFilename}"?`)) {
      setIsDeleting(true);

      try {
        const response = await fetchWithCsrf(
          `/api/admin/image/${selectedFilename}`,
          { method: "DELETE" }
        );

        const result = await response.json();
        if (result.success) {
          alert(`Success. "${selectedFilename}" has been deleted.`);
          location.reload();
        } else {
          throw new Error();
        }
      } catch (e) {
        alert(`Failed to delete ${selectedFilename}.`);
        setIsDeleting(false);
      }
    }
  };

  return (
    <div className="admin-image-manager">
      <h2>Manage Images</h2>
      <span>
        <ImageFilenameSelect
          options={imageFilenames}
          onChange={setSelectedFilename}
        />
        <button
          className="admin-image-manager__delete-button"
          disabled={!selectedFilename || isDeleting}
          onClick={handleClickDelete}
        >
          {isDeleting ? "Deleting..." : "Delete..."}
        </button>
      </span>
      {selectedFilename && (
        <div className="admin-image-manager__preview-container">
          <S3ImageThumbnail filename={selectedFilename} />
        </div>
      )}
      <h2>Upload New Image</h2>
      <ImageUpload />
    </div>
  );
};

export default ImageManagerContainer;
