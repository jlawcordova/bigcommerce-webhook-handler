import { BigCommerceCallbackPayload } from "./bigcommerce";

export function process(payload: BigCommerceCallbackPayload) {
    // Create the processing logic for a BigCommerce callback payload here.
    console.log(JSON.stringify(payload));
}