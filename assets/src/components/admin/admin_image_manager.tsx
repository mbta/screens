import { useCallback, useEffect, useState } from "react";
import { useDropzone } from "react-dropzone";
import _ from "lodash";

import { fetch } from "Util/admin";

type FileWithUrl = {
  file: File;
  url: string;
};

type ImageEntry = {
  key: string;
  url: string;
};

const keyPrefix = (key: string) => key.split("/").slice(0, -1).join("/");

const ImageThumbnail = ({ src }): JSX.Element => (
  <img className="admin-image-manager__thumbnail" src={src} />
);

const ImageUpload = ({ onUploaded, selectedPrefix }): JSX.Element => {
  const [uploadKey, setUploadKey] = useState("");
  const [stagedUpload, setStagedUpload] = useState<FileWithUrl | null>(null);
  const [isUploading, setIsUploading] = useState(false);

  const handleClickUpload = async () => {
    if (!stagedUpload) return;

    if (
      keyPrefix(uploadKey) == "" &&
      !confirm("Really upload this image to the root path?")
    )
      return;

    setIsUploading(true);

    const formData = new FormData();
    formData.append("key", uploadKey);
    formData.append("image", stagedUpload.file, stagedUpload.file.name);

    try {
      const result = await fetch.formData("/api/admin/images", formData);

      if (result.success) {
        alert(`Success. Image has been uploaded.`);
        setStagedUpload(null);
        onUploaded(uploadKey);
      } else {
        throw new Error();
      }
    } catch {
      alert("Upload failed.");
    } finally {
      setIsUploading(false);
    }
  };

  const onDrop = useCallback(
    ([acceptedFile]) => {
      if (acceptedFile) {
        setStagedUpload({
          file: acceptedFile,
          url: URL.createObjectURL(acceptedFile),
        });
        setUploadKey(
          (selectedPrefix ? selectedPrefix + "/" : "") + acceptedFile.name,
        );
      } else {
        alert("That file is too large; please try one under 20MB.");
      }
    },
    [selectedPrefix, setStagedUpload],
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
          <strong>PNG, GIF, or SVG only. 20MB max.</strong>
        </p>
      </div>
      {stagedUpload && (
        <>
          <p>
            <label>
              Path:
              <input
                onChange={(e) => setUploadKey(e.target.value)}
                size={80}
                value={uploadKey}
              />
            </label>
            <button
              className="admin-image-manager__upload-button"
              disabled={isUploading}
              onClick={handleClickUpload}
            >
              {isUploading ? "Uploading..." : "Upload"}
            </button>
          </p>
          <ImageThumbnail src={stagedUpload.url} />
        </>
      )}
    </>
  );
};

const ImageManager = (): JSX.Element => {
  const [images, setImages] = useState<ImageEntry[]>([]);
  const [selectedKey, setSelectedKey] = useState<string | undefined>(undefined);
  const [isDeleting, setIsDeleting] = useState(false);

  const loadImages = async (selectKey = undefined) => {
    setImages([]);
    setSelectedKey(undefined);
    const { images } = await fetch.get("/api/admin/images");
    setImages(images);
    setSelectedKey(selectKey);
  };

  useEffect(() => {
    loadImages();
    return;
  }, []);

  const imageUrls = Object.fromEntries(
    images.map(({ key, url }) => [key, url]),
  );

  const imageGroups = _.groupBy(
    images.map(({ key }) => key),
    (key) => {
      const [first, ...rest] = key.split("/");
      return rest.length > 0 ? first : "(root)";
    },
  );

  const handleClickDelete = async () => {
    if (selectedKey && confirm(`Permanently delete "${selectedKey}"?`)) {
      setIsDeleting(true);

      try {
        const result = await fetch.delete(
          `/api/admin/images/${encodeURIComponent(selectedKey)}`,
        );

        if (result.success) {
          alert(`Success. "${selectedKey}" has been deleted.`);
          loadImages();
        } else {
          throw new Error();
        }
      } catch {
        alert(`Failed to delete ${selectedKey}.`);
      } finally {
        setIsDeleting(false);
      }
    }
  };

  return (
    <div className="admin-image-manager">
      <h2>Manage Images</h2>
      <span>
        <select
          disabled={images.length == 0}
          onChange={(e) => setSelectedKey(e.target.value)}
          value={selectedKey}
        >
          <option value={undefined}></option>
          {_.sortBy(Object.keys(imageGroups)).map((group) => (
            <optgroup key={group} label={group}>
              {_.sortBy(imageGroups[group]).map((key) => (
                <option key={key} value={key}>
                  {key}
                </option>
              ))}
            </optgroup>
          ))}
        </select>
        <button
          className="admin-image-manager__delete-button"
          disabled={!selectedKey || isDeleting}
          onClick={handleClickDelete}
        >
          {isDeleting ? "Deleting..." : "Delete..."}
        </button>
      </span>
      {selectedKey && (
        <div className="admin-image-manager__preview-container">
          <img
            className="admin-image-manager__thumbnail"
            src={imageUrls[selectedKey]}
          />
          <p>
            <a target="_blank" rel="noreferrer" href={imageUrls[selectedKey]}>
              View at full size
            </a>
          </p>
          <p>
            <button
              onClick={() =>
                navigator.clipboard.writeText(`images/${selectedKey}`)
              }
            >
              Copy path to clipboard
            </button>
          </p>
        </div>
      )}
      <h2>Upload New Image</h2>
      <ImageUpload
        onUploaded={loadImages}
        selectedPrefix={selectedKey ? keyPrefix(selectedKey) : undefined}
      />
    </div>
  );
};

export default ImageManager;
