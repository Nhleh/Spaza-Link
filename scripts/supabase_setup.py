"""One-off Supabase setup: create the admin account + seed the 20 categories.

Reads credentials from the environment (never hard-code the secret key):
    SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, SUPABASE_SECRET_KEY

Run:  python scripts/supabase_setup.py
"""
import json, os, re, sys, urllib.request, urllib.error

URL    = os.environ.get("SUPABASE_URL", "")
ANON   = os.environ.get("SUPABASE_PUBLISHABLE_KEY", "")
SECRET = os.environ.get("SUPABASE_SECRET_KEY", "")
if not (URL and ANON and SECRET):
    sys.exit("Set SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, SUPABASE_SECRET_KEY first.")

def req(method, path, body=None, key=None, extra=None):
    key = key or SECRET
    headers = {"apikey": key, "Authorization": f"Bearer {key}",
               "Content-Type": "application/json"}
    if extra: headers.update(extra)
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(URL + path, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(r) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()

# 1) Verify schema + publishable key
st, bd = req("GET", "/rest/v1/categories?select=id&limit=1", key=ANON)
print(f"[verify] categories (anon): HTTP {st}")

# 2) Admin auth user -> role=admin
st, bd = req("POST", "/auth/v1/admin/users",
             {"email": "ndabezinhlencama@gmail.com", "password": "Aa206328/*",
              "email_confirm": True})
uid = None
try: uid = json.loads(bd).get("id")
except Exception: pass
if not uid:
    _, bd2 = req("GET", "/auth/v1/admin/users?per_page=200")
    for u in json.loads(bd2).get("users", []):
        if u.get("email") == "ndabezinhlencama@gmail.com":
            uid = u["id"]; break
if uid:
    req("PATCH", f"/rest/v1/profiles?id=eq.{uid}",
        {"role": "admin", "display_name": "Ndabezinhle",
         "email": "ndabezinhlencama@gmail.com"})
print(f"[admin] uid={uid} promoted to admin")

# 3) Seed the 20 categories
CATS = [
  ("Beverages","\U0001F964",["Soft Drinks","Energy Drinks","Water","Juice","Ice Tea"]),
  ("Bread & Bakery","\U0001F35E",["Bread","Buns","Rolls","Cakes"]),
  ("Maize & Grains","\U0001F33D",["Maize Meal","Rice","Samp","Flour"]),
  ("Cooking Essentials","\U0001F9C2",["Cooking Oil","Salt","Sugar","Spices","Stock Cubes"]),
  ("Dairy","\U0001F95B",["Milk","Long Life Milk","Cheese","Butter","Margarine","Yoghurt"]),
  ("Breakfast","\U0001F963",["Cereals","Oats","Peanut Butter","Jam"]),
  ("Canned Foods","\U0001F96B",["Baked Beans","Pilchards","Corn","Tomatoes","Mixed Vegetables"]),
  ("Snacks","\U0001F36B",["Chips","Biscuits","Chocolates","Sweets","Popcorn"]),
  ("Instant Foods","\U0001F35C",["Instant Noodles","Soup","Cup Meals"]),
  ("Frozen Foods","\U0001F9CA",["Chicken","Fish","Frozen Vegetables","Frozen Chips"]),
  ("Fresh Produce","\U0001F96C",["Potatoes","Onions","Tomatoes","Fruits","Vegetables"]),
  ("Meat","\U0001F357",["Beef","Chicken","Sausages","Polony"]),
  ("Toiletries","\U0001F9FC",["Soap","Toothpaste","Toothbrushes","Deodorant","Lotion"]),
  ("Baby Products","\U0001F37C",["Diapers","Baby Wipes","Baby Formula"]),
  ("Cleaning Products","\U0001F9FD",["Washing Powder","Dishwashing Liquid","Bleach","Pine Gel","Toilet Cleaner"]),
  ("Laundry","\U0001F9FA",["Fabric Softener","Washing Soap","Stain Remover"]),
  ("Household","\U0001F9FB",["Toilet Paper","Paper Towels","Foil","Refuse Bags","Candles","Matches"]),
  ("Stationery","✏️",["Pens","Pencils","Exercise Books","Printing Paper"]),
  ("Airtime & Electricity","\U0001F4F1",["Airtime","Data Bundles","Electricity Vouchers"]),
  ("Promotions & Specials","\U0001F3F7️",["Weekly Specials","Combo Deals","Clearance Items"]),
]
def slug(n): return re.sub(r'[^a-z0-9]+', '-', n.lower()).strip('-')
rows = [{"id":slug(n),"name":n,"slug":slug(n),"icon_url":emo,"image_url":"",
         "sort_order":i+1,"is_available":True,"product_count":0,"subcategories":subs}
        for i,(n,emo,subs) in enumerate(CATS)]
st, bd = req("POST", "/rest/v1/categories", rows,
             extra={"Prefer": "resolution=merge-duplicates,return=minimal"})
print(f"[seed] 20 categories upsert: HTTP {st}")
