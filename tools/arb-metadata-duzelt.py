import json
import os
import glob

ARB_DIR = r"C:\yeedoy\apps\mobile_flutter\lib\l10n"  # gerekirse değiştir
DEFAULT_DESC_PREFIX = "TODO: "  # istersen boş bırak

def is_message_key(k: str) -> bool:
    # ARB metadata keys start with '@'
    return not k.startswith("@")

def ensure_metadata(obj: dict) -> tuple[dict, int]:
    added = 0

    # ARB'de "@" ile başlayanlar metadata; geri kalanı mesaj
    for k in list(obj.keys()):
        if not is_message_key(k):
            continue

        meta_key = f"@{k}"
        if meta_key not in obj:
            obj[meta_key] = {
                "description": f"{DEFAULT_DESC_PREFIX}{k}".strip()
            }
            added += 1
        else:
            # metadata var ama description yoksa ekle
            if isinstance(obj[meta_key], dict) and "description" not in obj[meta_key]:
                obj[meta_key]["description"] = f"{DEFAULT_DESC_PREFIX}{k}".strip()
                added += 1

    return obj, added

def main():
    files = glob.glob(os.path.join(ARB_DIR, "*.arb"))
    if not files:
        print(f"ARB bulunamadı: {ARB_DIR}")
        return

    total_added = 0
    for path in files:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)

        data, added = ensure_metadata(data)
        total_added += added

        # JSON formatı bozulmasın diye pretty yaz
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")

        print(f"{os.path.basename(path)} -> eklendi/duzeltildi: {added}")

    print(f"\nTOPLAM eklenen/duzeltilen metadata: {total_added}")

if __name__ == "__main__":
    main()