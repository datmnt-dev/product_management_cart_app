const fs = require("fs");
const path = require("path");

const projectId = "product-management-cart-app";
const root = path.resolve(__dirname, "..");
const firebaseOptions = fs.readFileSync(
  path.join(root, "lib", "firebase_options.dart"),
  "utf8",
);
const apiKey = firebaseOptions.match(/static const FirebaseOptions web = FirebaseOptions\([\s\S]*?apiKey: '([^']+)'/)?.[1];

if (!apiKey) {
  throw new Error("Cannot find Firebase Web API key in lib/firebase_options.dart");
}

const firestoreBase = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

async function main() {
  const auth = await postJson(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      email: "admin@store.local",
      password: "123456",
      returnSecureToken: true,
    },
  );

  if (auth.error) {
    throw new Error(auth.error.message);
  }

  const counts = {};
  for (const collection of ["users", "products", "coupons", "inventoryMovements", "orders", "seedRuns"]) {
    counts[collection] = await countCollection(collection, auth.idToken);
  }
  console.log(JSON.stringify(counts, null, 2));
}

async function countCollection(collection, idToken) {
  const response = await fetch(`${firestoreBase}/${collection}?pageSize=100`, {
    headers: {
      Authorization: `Bearer ${idToken}`,
    },
  });
  if (!response.ok) {
    throw new Error(`${collection}: ${response.status} ${await response.text()}`);
  }
  const body = await response.json();
  return body.documents?.length ?? 0;
}

async function postJson(url, payload) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  return response.json();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
