// wp-upload-user — placeholder stub.
// This function is not yet implemented.
// Returns a 501 not_implemented response for all requests.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve((_req: Request) => {
  return new Response(
    JSON.stringify({ error: "not_implemented" }),
    {
      status: 501,
      headers: { "Content-Type": "application/json" },
    },
  );
});
