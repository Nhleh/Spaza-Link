import json, time, urllib.request, re

PROJ = "spazalink-d8a59"
BASE = f"http://127.0.0.1:8080/v1/projects/{PROJ}/databases/(default)/documents/categories"
NOW = int(time.time() * 1000)

# (name, emoji, [subcategories])
CATS = [
    ("Beverages", "\U0001F964", ["Soft Drinks", "Energy Drinks", "Water", "Juice", "Ice Tea"]),
    ("Bread & Bakery", "\U0001F35E", ["Bread", "Buns", "Rolls", "Cakes"]),
    ("Maize & Grains", "\U0001F33D", ["Maize Meal", "Rice", "Samp", "Flour"]),
    ("Cooking Essentials", "\U0001F9C2", ["Cooking Oil", "Salt", "Sugar", "Spices", "Stock Cubes"]),
    ("Dairy", "\U0001F95B", ["Milk", "Long Life Milk", "Cheese", "Butter", "Margarine", "Yoghurt"]),
    ("Breakfast", "\U0001F963", ["Cereals", "Oats", "Peanut Butter", "Jam"]),
    ("Canned Foods", "\U0001F96B", ["Baked Beans", "Pilchards", "Corn", "Tomatoes", "Mixed Vegetables"]),
    ("Snacks", "\U0001F36B", ["Chips", "Biscuits", "Chocolates", "Sweets", "Popcorn"]),
    ("Instant Foods", "\U0001F35C", ["Instant Noodles", "Soup", "Cup Meals"]),
    ("Frozen Foods", "\U0001F9CA", ["Chicken", "Fish", "Frozen Vegetables", "Frozen Chips"]),
    ("Fresh Produce", "\U0001F96C", ["Potatoes", "Onions", "Tomatoes", "Fruits", "Vegetables"]),
    ("Meat", "\U0001F357", ["Beef", "Chicken", "Sausages", "Polony"]),
    ("Toiletries", "\U0001F9FC", ["Soap", "Toothpaste", "Toothbrushes", "Deodorant", "Lotion"]),
    ("Baby Products", "\U0001F37C", ["Diapers", "Baby Wipes", "Baby Formula"]),
    ("Cleaning Products", "\U0001F9FD", ["Washing Powder", "Dishwashing Liquid", "Bleach", "Pine Gel", "Toilet Cleaner"]),
    ("Laundry", "\U0001F9FA", ["Fabric Softener", "Washing Soap", "Stain Remover"]),
    ("Household", "\U0001F9FB", ["Toilet Paper", "Paper Towels", "Foil", "Refuse Bags", "Candles", "Matches"]),
    ("Stationery", "✏️", ["Pens", "Pencils", "Exercise Books", "Printing Paper"]),
    ("Airtime & Electricity", "\U0001F4F1", ["Airtime", "Data Bundles", "Electricity Vouchers"]),
    ("Promotions & Specials", "\U0001F3F7️", ["Weekly Specials", "Combo Deals", "Clearance Items"]),
]

def slugify(name):
    return re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')

ok = 0
for i, (name, emoji, subs) in enumerate(CATS, start=1):
    slug = slugify(name)
    fields = {
        "id": {"stringValue": slug},
        "name": {"stringValue": name},
        "slug": {"stringValue": slug},
        "iconUrl": {"stringValue": emoji},
        "imageUrl": {"stringValue": ""},
        "sortOrder": {"integerValue": str(i)},
        "isAvailable": {"booleanValue": True},
        "productCount": {"integerValue": "0"},
        "createdAt": {"integerValue": str(NOW)},
        "subcategories": {"arrayValue": {"values": [{"stringValue": s} for s in subs]}},
    }
    body = json.dumps({"fields": fields}).encode()
    # PATCH = upsert by documentId (idempotent, re-runnable)
    url = f"{BASE}/{slug}"
    req = urllib.request.Request(url, data=body, method="PATCH",
                                 headers={"Authorization": "Bearer owner", "Content-Type": "application/json"})
    try:
        urllib.request.urlopen(req).read()
        ok += 1
        print(f"  {i:2d}. {emoji} {name}  ({len(subs)} subcategories)")
    except Exception as e:
        print(f"  !! {name}: {e}")

print(f"\nSeeded {ok}/{len(CATS)} categories.")
