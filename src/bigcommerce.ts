export interface BigCommerceCallbackPayload {
  scope: String;
  store_id: String;
  data: BigCommerceCallbackPayloadData;
  hash: String;
  created_at: Number;
  producer: String;
}

export interface BigCommerceCallbackPayloadData {
  type: String;
  id: Number;
}
