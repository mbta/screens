const getCsrfToken = (): string => document?.head?.querySelector<HTMLMetaElement>(
  "[name~=csrf-token][content]"
)?.content ?? "";

export default getCsrfToken;
