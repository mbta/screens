import React, { useCallback, useEffect, useState } from "react";
import { useDropzone } from "react-dropzone";
import _ from "lodash";

interface FileWithPreview extends File {
  preview: string;
}

const IMAGE_BUCKET_BASE_URL =
  "https://mbta-dotcom.s3.amazonaws.com/screens/images/psa/";

const fetchWithCsrf = (resource: RequestInfo, init: RequestInit = {}) => {
  const csrfToken = document.head.querySelector("[name~=csrf-token][content]")
    .content;
  return fetch(resource, {
    ...init,
    headers: { ...(init?.headers || {}), "x-csrf-token": csrfToken },
    credentials: "include",
  });
};

const fetchImageNames = async () => {
  const response = await fetchWithCsrf("/api/admin/image_names");
  const { image_names: imageNames } = await response.json();
  return _.sortBy(imageNames);
};

const ImageNameSelect = ({ options, onChange }): JSX.Element => {
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

const S3ImageThumbnail = ({ imageName }): JSX.Element => (
  <ImageThumbnail src={`${IMAGE_BUCKET_BASE_URL}${imageName}.png`} fullSize />
);

const ImageManagerContainer = ({}): JSX.Element => {
  const [imageNames, setImageNames] = useState<string[]>([]);

  const loadState = async () => {
    setImageNames(await fetchImageNames());
  };

  useEffect(() => {
    loadState();
    return;
  }, []);

  return imageNames.length > 0 ? (
    <ImageManager imageNames={imageNames} />
  ) : (
    <div>Loading...</div>
  );
};

const ImageUpload = ({}): JSX.Element => {
  const [stagedImageUpload, setStagedImageUpload] = useState<FileWithPreview>(
    null
  );

  const handleClickUpload = async () => {
    const formData = new FormData();
    formData.append("image", stagedImageUpload, stagedImageUpload.name);
    try {
      const response = await fetchWithCsrf("/api/admin/image", {
        method: "POST",
        body: formData,
      });
      const result = await response.json();
      if (result.success) {
        alert(
          `Success. Image has been uploaded to S3 as "${result.uploaded_name}".`
        );
        location.reload();
      } else {
        throw new Error();
      }
    } catch (e) {
      alert("Upload failed.");
    }
  };

  const onDrop = useCallback(
    ([acceptedFile]) => {
      const fileWithPreview = Object.assign(acceptedFile, {
        preview: URL.createObjectURL(acceptedFile),
      });
      setStagedImageUpload(fileWithPreview);
    },
    [setStagedImageUpload]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: "image/png",
    multiple: false,
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
        <p>PNGs only. Make sure your image has the name you want to use!</p>
      </div>
      {stagedImageUpload != null && (
        <ImageThumbnail src={stagedImageUpload.preview} />
      )}
      <button
        className="admin-image-manager__upload-button"
        disabled={stagedImageUpload == null}
        onClick={handleClickUpload}
      >
        Upload
      </button>
    </>
  );
};

const ImageManager = ({ imageNames }): JSX.Element => {
  const [selectedImageName, setSelectedImageName] = useState(undefined);

  const handleClickDelete = async () => {
    if (confirm(`Permanently delete "${selectedImageName}.png"?`)) {
      try {
        const response = await fetchWithCsrf(
          `/api/admin/image/${selectedImageName}`,
          { method: "DELETE" }
        );
        const { success } = await response.json();
        if (success) {
          alert(`Success. "${selectedImageName}.png" has been deleted.`);
          location.reload();
        } else {
          throw new Error();
        }
      } catch (e) {
        alert(`Failed to delete ${selectedImageName}.`);
      }
    }
  };

  return (
    <div className="admin-image-manager">
      <h2>Manage Images</h2>
      <span>
        <ImageNameSelect options={imageNames} onChange={setSelectedImageName} />
        <button
          className="admin-image-manager__delete-button"
          disabled={!selectedImageName}
          onClick={handleClickDelete}
        >
          Delete...
        </button>
      </span>
      {selectedImageName && (
        <div className="admin-image-manager__preview-container">
          <S3ImageThumbnail imageName={selectedImageName} />
        </div>
      )}
      <h2>Upload New Image</h2>
      <ImageUpload />
    </div>
  );
};

export default ImageManagerContainer;
