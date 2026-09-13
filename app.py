import os
import uuid
import hashlib
from datetime import datetime
from io import BytesIO

import pandas as pd
import streamlit as st
from sqlalchemy import (
    create_engine, Column, Integer, String, Float, Text, DateTime,
    ForeignKey, LargeBinary, func
)
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from sqlalchemy.exc import IntegrityError

# ============================================================
# CraftConnect – Streamlit Python prototype
# Database: PostgreSQL via DATABASE_URL, SQLite fallback for demo
# ============================================================

st.set_page_config(
    page_title="CraftConnect",
    page_icon="🧶",
    layout="wide",
    initial_sidebar_state="expanded",
)

Base = declarative_base()


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    name = Column(String(120), nullable=False)
    email = Column(String(160), unique=True, nullable=False)
    phone = Column(String(30), nullable=False)
    password_hash = Column(String(128), nullable=False)
    role = Column(String(20), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    artisan_profile = relationship("ArtisanProfile", back_populates="user", uselist=False)
    products = relationship("Product", back_populates="artisan")


class ArtisanProfile(Base):
    __tablename__ = "artisan_profiles"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    profile_image = Column(LargeBinary, nullable=True)
    location = Column(String(120), default="")
    craft_type = Column(String(100), default="")
    experience = Column(Integer, default=0)
    bio = Column(Text, default="")

    user = relationship("User", back_populates="artisan_profile")


class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True)
    artisan_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(180), nullable=False)
    image = Column(LargeBinary, nullable=True)
    category = Column(String(100), nullable=False)
    description = Column(Text, default="")
    material = Column(String(160), default="")
    craft_type = Column(String(100), default="")
    price = Column(Float, nullable=False)
    stock = Column(Integer, default=0)
    dimensions = Column(String(100), default="")
    delivery_time = Column(String(100), default="")
    ai_content = Column(Text, default="")
    rating = Column(Float, default=4.5)
    created_at = Column(DateTime, default=datetime.utcnow)

    artisan = relationship("User", back_populates="products")


class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    total_amount = Column(Float, nullable=False)
    status = Column(String(30), default="New")
    delivery_address = Column(Text, nullable=False)
    contact_number = Column(String(30), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class OrderItem(Base):
    __tablename__ = "order_items"
    id = Column(Integer, primary_key=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)


class CartItem(Base):
    __tablename__ = "cart_items"
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, default=1)


def db_url():
    # Streamlit Cloud: add DATABASE_URL under Settings > Secrets.
    # PostgreSQL example:
    # postgresql+psycopg://user:password@host:5432/database
    url = os.getenv("DATABASE_URL")
    if not url:
        try:
            url = st.secrets.get("DATABASE_URL")
        except Exception:
            url = None
    return url or "sqlite:///craftconnect.db"


@st.cache_resource
def get_engine():
    return create_engine(db_url(), pool_pre_ping=True)


@st.cache_resource
def get_session_factory():
    Base.metadata.create_all(get_engine())
    return sessionmaker(bind=get_engine(), expire_on_commit=False)


SessionLocal = get_session_factory()


def db():
    return SessionLocal()


def hash_password(password):
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


def valid_email(email):
    return "@" in email and "." in email.split("@")[-1]


def init_demo_data():
    """Seed products and artisan profiles once, but never seed a password."""
    s = db()
    try:
        if s.query(Product).count() > 0:
            return

        demo_artisans = [
            ("Meera Sharma", "meera@craftconnect.demo", "9876500001", "Jaipur, Rajasthan", "Blue Pottery", 12,
             "Traditional blue pottery artisan preserving Jaipur's hand-painted ceramic heritage."),
            ("Ramesh Kumar", "ramesh@craftconnect.demo", "9876500002", "Kutch, Gujarat", "Woodcraft", 18,
             "Woodworker creating detailed hand-carved boxes and traditional decor."),
            ("Sita Devi", "sita@craftconnect.demo", "9876500003", "Varanasi, Uttar Pradesh", "Handloom", 15,
             "Handloom artisan focused on elegant, small-batch textiles."),
        ]

        users = []
        for name, email, phone, loc, craft, exp, bio in demo_artisans:
            u = User(name=name, email=email, phone=phone, role="Artisan",
                     password_hash=hash_password(uuid.uuid4().hex))
            s.add(u)
            s.flush()
            s.add(ArtisanProfile(user_id=u.id, location=loc, craft_type=craft,
                                 experience=exp, bio=bio))
            users.append(u)

        s.flush()
        samples = [
            (users[0].id, "Blue Pottery Vase", "Pottery",
             "Hand-painted Jaipur blue pottery vase with a refined floral motif.",
             "Quartz, natural pigments", "Blue Pottery", 1299, 14, "18 x 10 cm", "5–7 days", 4.8),
            (users[0].id, "Rajasthani Wall Art", "Painting",
             "A vibrant handcrafted folk-art panel inspired by Rajasthan's desert culture.",
             "Handmade paper, natural colors", "Folk Painting", 1899, 8, "30 x 24 cm", "4–6 days", 4.7),
            (users[1].id, "Wooden Hand-Carved Box", "Woodcraft",
             "Intricately carved wooden storage box made by hand for jewelry and keepsakes.",
             "Sheesham wood", "Woodcraft", 1599, 10, "20 x 12 x 8 cm", "7–10 days", 4.9),
            (users[2].id, "Handloom Dupatta", "Handloom",
             "Lightweight handwoven dupatta with traditional motifs and a soft finish.",
             "Cotton-silk blend", "Handloom", 2199, 12, "220 x 70 cm", "5–8 days", 4.6),
            (users[1].id, "Traditional Metal Craft", "Metal Craft",
             "Decorative handcrafted metal piece inspired by traditional Indian forms.",
             "Brass", "Metal Craft", 2499, 5, "22 x 14 cm", "7–12 days", 4.8),
            (users[2].id, "Embroidered Handbag", "Embroidery",
             "Colorful hand-embroidered handbag combining everyday utility with folk artistry.",
             "Cotton, thread", "Embroidery", 999, 20, "28 x 24 cm", "4–6 days", 4.7),
            (users[0].id, "Terracotta Pot", "Pottery",
             "Hand-shaped terracotta planter with a rustic natural finish.",
             "Terracotta clay", "Pottery", 699, 25, "20 x 20 cm", "3–5 days", 4.5),
            (users[2].id, "Handmade Jewelry Set", "Jewelry",
             "Artisan-made statement jewelry set with traditional-inspired detailing.",
             "Beads, alloy", "Jewelry", 1199, 9, "Adjustable", "5–7 days", 4.6),
        ]

        for row in samples:
            s.add(Product(
                artisan_id=row[0], name=row[1], category=row[2],
                description=row[3], material=row[4], craft_type=row[5],
                price=row[6], stock=row[7], dimensions=row[8],
                delivery_time=row[9], rating=row[10],
                ai_content=""
            ))
        s.commit()
    finally:
        s.close()


def current_user():
    uid = st.session_state.get("user_id")
    if not uid:
        return None
    s = db()
    try:
        return s.get(User, uid)
    finally:
        s.close()


def ai_catalog(product_name, category, material, craft_type, description):
    title = product_name.strip().title() or f"Handcrafted {category}"
    short = (
        f"A beautifully handcrafted {category.lower()} made using {material.lower() or 'traditional materials'}, "
        f"showcasing the skill and character of Indian artisan craft."
    )
    detailed = (
        f"{title} is a thoughtfully made {craft_type.lower() or category.lower()} piece. "
        f"{description.strip() or 'Each piece is created in small batches with attention to traditional technique and finish.'} "
        f"The natural variations of handmade production make every piece distinctive."
    )
    story = (
        f"Crafted through the traditions of {craft_type.lower() or 'Indian handicraft'}, this piece reflects "
        f"the time, patience and cultural knowledge passed through artisan communities. "
        f"Buying it helps keep skilled craft traditions connected to modern customers."
    )
    tags = ", ".join([
        "handmade", "Indian handicraft", craft_type.lower() if craft_type else "artisan craft",
        category.lower(), "traditional craft", "sustainable gifting"
    ])
    keywords = ", ".join([
        title.lower(), "artisan made", "Indian crafts", category.lower(),
        craft_type.lower() if craft_type else "traditional craft"
    ])
    return {
        "Product Title": title,
        "Short Description": short,
        "Detailed Description": detailed,
        "Craft Story": story,
        "Suggested Category": category or "Handicrafts",
        "Suggested Tags": tags,
        "Suggested Keywords": keywords,
    }


def placeholder_image():
    # No external image dependency: a simple SVG-like visual as fallback is not used
    # because Streamlit image expects actual image bytes. Cards simply show an emoji.
    return None


# ------------------------- Styling -------------------------

st.markdown("""
<style>
:root { --cc-brown:#6f4528; --cc-orange:#b85c28; --cc-cream:#fbf5eb; }
.block-container { padding-top: 1.2rem; max-width: 1200px; }
.cc-hero {
    padding: 2rem; border-radius: 24px;
    background: linear-gradient(135deg, #6f4528 0%, #a96032 55%, #d18a4a 100%);
    color: white; margin-bottom: 1.3rem;
}
.cc-hero h1 { font-size: 2.7rem; margin: 0; }
.cc-hero p { font-size: 1.05rem; opacity: .94; }
.card {
    border: 1px solid #eadfce; border-radius: 18px; padding: 1rem;
    background: #fffdf9; min-height: 160px; margin-bottom: 1rem;
}
.metric {
    border-radius: 16px; padding: 1rem; background: #fff7ec;
    border: 1px solid #f0dfc8;
}
.metric .value { font-size: 1.65rem; font-weight: 700; color:#6f4528; }
.metric .label { color:#6d6258; font-size:.9rem; }
.small-muted { color:#766e66; font-size:.88rem; }
.badge { padding:.2rem .55rem; border-radius:999px; background:#f4e7d7; color:#6f4528; }
</style>
""", unsafe_allow_html=True)

CATEGORIES = ["All", "Pottery", "Handloom", "Woodcraft", "Jewelry", "Painting",
              "Embroidery", "Metal Craft", "Home Decor"]


def metric_card(label, value):
    st.markdown(
        f'<div class="metric"><div class="value">{value}</div><div class="label">{label}</div></div>',
        unsafe_allow_html=True
    )


def logout():
    for k in ["user_id", "page", "cart"]:
        st.session_state.pop(k, None)
    st.rerun()


def login_page():
    st.markdown("""
    <div class="cc-hero">
      <h1>🧶 CraftConnect</h1>
      <p>Connecting Crafts to the World</p>
      <p>AI-driven market linkage and smart cataloging for India's artisans.</p>
    </div>
    """, unsafe_allow_html=True)

    tab1, tab2, tab3 = st.tabs(["Login", "Register", "Demo"])

    with tab1:
        with st.form("login_form"):
            email = st.text_input("Email")
            password = st.text_input("Password", type="password")
            submitted = st.form_submit_button("Login", use_container_width=True)
        if submitted:
            s = db()
            try:
                u = s.query(User).filter(func.lower(User.email) == email.strip().lower()).first()
                if u and u.password_hash == hash_password(password):
                    st.session_state.user_id = u.id
                    st.session_state.page = "home"
                    st.success("Login successful!")
                    st.rerun()
                else:
                    st.error("Invalid email or password.")
            finally:
                s.close()
        st.caption("Forgot password? For this prototype, contact the administrator or register a new account.")

    with tab2:
        with st.form("register_form"):
            name = st.text_input("Full Name")
            email = st.text_input("Email", key="reg_email")
            phone = st.text_input("Phone Number")
            password = st.text_input("Password", type="password", key="reg_pw")
            confirm = st.text_input("Confirm Password", type="password")
            role = st.selectbox("Role", ["Artisan", "Customer"])
            submitted = st.form_submit_button("Create Account", use_container_width=True)

        if submitted:
            errors = []
            if len(name.strip()) < 2:
                errors.append("Enter your full name.")
            if not valid_email(email):
                errors.append("Enter a valid email.")
            if len(phone.strip()) < 8:
                errors.append("Enter a valid phone number.")
            if len(password) < 6:
                errors.append("Password must be at least 6 characters.")
            if password != confirm:
                errors.append("Passwords do not match.")
            if errors:
                for e in errors:
                    st.error(e)
            else:
                s = db()
                try:
                    u = User(name=name.strip(), email=email.strip().lower(), phone=phone.strip(),
                             password_hash=hash_password(password), role=role)
                    s.add(u)
                    s.flush()
                    if role == "Artisan":
                        s.add(ArtisanProfile(user_id=u.id))
                    s.commit()
                    st.success("Account created. Go to Login to continue.")
                except IntegrityError:
                    s.rollback()
                    st.error("An account with this email already exists.")
                finally:
                    s.close()

    with tab3:
        st.info("Sample artisan products are loaded automatically. To create an admin account, set ADMIN_EMAIL and ADMIN_PASSWORD in your environment/Streamlit Secrets, then log in with those values.")
        st.markdown("**Demo artisan:** `meera@craftconnect.demo`")
        st.markdown("**Demo customer:** create a customer account from Register.")
        st.warning("Demo artisan passwords are intentionally not hardcoded. Create your own account for secure testing.")


def artisan_home(u):
    s = db()
    products = s.query(Product).filter_by(artisan_id=u.id).all()
    product_ids = [p.id for p in products]
    orders = []
    if product_ids:
        orders = s.query(OrderItem).filter(OrderItem.product_id.in_(product_ids)).all()
    order_ids = list({x.order_id for x in orders})
    all_orders = s.query(Order).filter(Order.id.in_(order_ids)).all() if order_ids else []
    delivered = [o for o in all_orders if o.status == "Delivered"]
    earnings = sum(o.total_amount for o in delivered)
    pending = len([o for o in all_orders if o.status in ["New", "Processing"]])
    s.close()

    st.markdown(f"## Welcome, {u.name.split()[0]} 👋")
    st.caption("Your craft business at a glance.")

    cols = st.columns(4)
    with cols[0]: metric_card("Total Products", len(products))
    with cols[1]: metric_card("Total Orders", len(all_orders))
    with cols[2]: metric_card("Total Earnings", f"₹{earnings:,.0f}")
    with cols[3]: metric_card("Pending Orders", pending)

    st.write("")
    if st.button("➕ Add Product", type="primary"):
        st.session_state.page = "add_product"
        st.rerun()

    st.subheader("Recent Products")
    if products:
        cols = st.columns(3)
        for i, p in enumerate(products[:6]):
            with cols[i % 3]:
                st.markdown('<div class="card">', unsafe_allow_html=True)
                if p.image:
                    st.image(BytesIO(p.image), use_container_width=True)
                st.markdown(f"### {p.name}")
                st.write(f"₹{p.price:,.0f} · {p.category}")
                st.caption(f"Stock: {p.stock}")
                st.markdown("</div>", unsafe_allow_html=True)
    else:
        st.info("No products yet. Add your first handcrafted product.")


def artisan_profile(u):
    s = db()
    profile = s.query(ArtisanProfile).filter_by(user_id=u.id).first()
    s.close()
    st.header("Artisan Profile")
    with st.form("profile"):
        name = st.text_input("Artisan Name", value=u.name)
        phone = st.text_input("Phone", value=u.phone)
        email = st.text_input("Email", value=u.email)
        location = st.text_input("Location", value=profile.location if profile else "")
        craft = st.text_input("Craft Type", value=profile.craft_type if profile else "")
        exp = st.number_input("Years of Experience", min_value=0, max_value=100,
                              value=profile.experience if profile else 0)
        bio = st.text_area("About Artisan", value=profile.bio if profile else "")
        photo = st.file_uploader("Profile Photo", type=["png", "jpg", "jpeg"])
        save = st.form_submit_button("Save Profile", type="primary")
    if save:
        s = db()
        u2 = s.get(User, u.id)
        p = s.query(ArtisanProfile).filter_by(user_id=u.id).first()
        u2.name, u2.phone, u2.email = name.strip(), phone.strip(), email.strip().lower()
        if not p:
            p = ArtisanProfile(user_id=u.id)
            s.add(p)
        p.location, p.craft_type, p.experience, p.bio = location, craft, int(exp), bio
        if photo:
            p.profile_image = photo.getvalue()
        s.commit()
        s.close()
        st.success("Profile updated.")


def add_product():
    st.header("Add Product")
    st.caption("Upload a product image and generate professional catalog copy with the demo AI service.")
    with st.form("add_product_form"):
        name = st.text_input("Product Name")
        image = st.file_uploader("Product Image", type=["png", "jpg", "jpeg", "webp"])
        category = st.selectbox("Category", CATEGORIES[1:])
        craft = st.text_input("Craft Type", value=category)
        material = st.text_input("Material")
        desc = st.text_area("Description")
        price = st.number_input("Price (₹)", min_value=1.0, value=999.0, step=100.0)
        stock = st.number_input("Stock Quantity", min_value=0, value=1, step=1)
        dimensions = st.text_input("Dimensions")
        delivery = st.text_input("Estimated Delivery Time", value="5–7 days")
        generate = st.form_submit_button("✨ Generate AI Catalog", use_container_width=True)

    if generate:
        if not name.strip():
            st.error("Enter a product name first.")
        else:
            with st.spinner("AI is creating your professional catalog content..."):
                st.session_state.ai_result = ai_catalog(name, category, material, craft, desc)
            st.success("Catalog generated. Review and edit it below before saving.")

    ai = st.session_state.get("ai_result")
    if ai:
        st.subheader("AI Catalog Preview")
        edited = {}
        for k, v in ai.items():
            if "Description" in k or "Story" in k:
                edited[k] = st.text_area(k, v, key=f"ai_{k}")
            else:
                edited[k] = st.text_input(k, v, key=f"ai_{k}")

        if st.button("💾 Save Product", type="primary"):
            u = current_user()
            s = db()
            p = Product(
                artisan_id=u.id,
                name=edited["Product Title"],
                image=image.getvalue() if image else None,
                category=edited["Suggested Category"],
                description=edited["Detailed Description"],
                material=material,
                craft_type=craft,
                price=float(price),
                stock=int(stock),
                dimensions=dimensions,
                delivery_time=delivery,
                ai_content=str(edited),
            )
            s.add(p)
            s.commit()
            s.close()
            st.session_state.pop("ai_result", None)
            st.success("Product saved successfully!")
            st.session_state.page = "products"
            st.rerun()


def artisan_products(u):
    st.header("My Products")
    s = db()
    products = s.query(Product).filter_by(artisan_id=u.id).order_by(Product.created_at.desc()).all()

    if not products:
        st.info("No products found.")
        s.close()
        return

    cols = st.columns(3)
    for i, p in enumerate(products):
        with cols[i % 3]:
            st.markdown('<div class="card">', unsafe_allow_html=True)
            if p.image:
                st.image(BytesIO(p.image), use_container_width=True)
            else:
                st.markdown("## 🧶")
            st.markdown(f"### {p.name}")
            st.write(f"**₹{p.price:,.0f}** · {p.category}")
            st.caption(f"Stock: {p.stock} · Rating: ⭐ {p.rating:.1f}")
            if st.button("Delete", key=f"del_{p.id}"):
                s.delete(p)
                s.commit()
                st.success("Product deleted.")
                st.rerun()
            st.markdown("</div>", unsafe_allow_html=True)
    s.close()


def artisan_orders(u):
    st.header("Orders")
    s = db()
    products = s.query(Product).filter_by(artisan_id=u.id).all()
    pids = [p.id for p in products]
    items = s.query(OrderItem).filter(OrderItem.product_id.in_(pids)).all() if pids else []
    oids = list({i.order_id for i in items})
    orders = s.query(Order).filter(Order.id.in_(oids)).order_by(Order.created_at.desc()).all() if oids else []

    if not orders:
        st.info("No orders yet.")
        s.close()
        return

    for o in orders:
        st.markdown(f"### Order #{o.id} · {o.status}")
        st.caption(f"{o.created_at:%d %b %Y, %I:%M %p} · ₹{o.total_amount:,.0f}")
        new_status = st.selectbox(
            "Update status",
            ["New", "Processing", "Shipped", "Delivered", "Cancelled"],
            index=["New", "Processing", "Shipped", "Delivered", "Cancelled"].index(o.status),
            key=f"status_{o.id}"
        )
        if st.button("Update", key=f"update_{o.id}"):
            o.status = new_status
            s.commit()
            st.success("Order status updated.")
            st.rerun()
        st.divider()
    s.close()


def artisan_earnings(u):
    st.header("Earnings")
    s = db()
    products = s.query(Product).filter_by(artisan_id=u.id).all()
    pids = [p.id for p in products]
    items = s.query(OrderItem).filter(OrderItem.product_id.in_(pids)).all() if pids else []
    oids = list({i.order_id for i in items})
    orders = s.query(Order).filter(Order.id.in_(oids), Order.status == "Delivered").all() if oids else []
    total = sum(o.total_amount for o in orders)
    rows = [{"Date": o.created_at.date(), "Revenue": o.total_amount} for o in orders]
    s.close()

    c1, c2, c3 = st.columns(3)
    with c1: metric_card("Total Earnings", f"₹{total:,.0f}")
    with c2: metric_card("Delivered Orders", len(orders))
    with c3: metric_card("Average Order", f"₹{(total / len(orders)) if orders else 0:,.0f}")
    if rows:
        df = pd.DataFrame(rows).groupby("Date", as_index=True)["Revenue"].sum()
        st.line_chart(df)
    else:
        st.info("Earnings will appear after delivered orders.")


def customer_home():
    st.markdown("""
    <div class="cc-hero">
      <h1>CraftConnect 🧶</h1>
      <p>Discover authentic Indian crafts, directly from artisans.</p>
    </div>
    """, unsafe_allow_html=True)

    s = db()
    products = s.query(Product).order_by(Product.rating.desc()).all()
    artisans = s.query(User).filter_by(role="Artisan").all()
    s.close()

    query = st.text_input("🔎 Search products, crafts or artisans", placeholder="Try: pottery, Jaipur, handloom...")
    cat = st.selectbox("Category", CATEGORIES)
    c1, c2, c3 = st.columns(3)
    with c1: min_price = st.number_input("Min price ₹", min_value=0, value=0)
    with c2: max_price = st.number_input("Max price ₹", min_value=0, value=10000)
    with c3: min_rating = st.slider("Minimum rating", 0.0, 5.0, 0.0, 0.1)

    filtered = []
    q = query.strip().lower()
    for p in products:
        artisan_name = p.artisan.name.lower() if p.artisan else ""
        text = f"{p.name} {p.category} {p.craft_type} {artisan_name}".lower()
        if q and q not in text:
            continue
        if cat != "All" and p.category != cat:
            continue
        if not (min_price <= p.price <= max_price):
            continue
        if p.rating < min_rating:
            continue
        filtered.append(p)

    st.subheader("Featured Products")
    if not filtered:
        st.info("No products match your filters.")
        return

    cols = st.columns(4)
    for i, p in enumerate(filtered[:12]):
        with cols[i % 4]:
            st.markdown('<div class="card">', unsafe_allow_html=True)
            if p.image:
                st.image(BytesIO(p.image), use_container_width=True)
            else:
                st.markdown("## 🧶")
            st.markdown(f"**{p.name}**")
            st.write(f"₹{p.price:,.0f}")
            st.caption(f"{p.category} · ⭐ {p.rating:.1f}")
            if st.button("View Details", key=f"view_{p.id}"):
                st.session_state.selected_product = p.id
                st.session_state.page = "product"
                st.rerun()
            st.markdown("</div>", unsafe_allow_html=True)

    st.subheader("Artisan Highlights")
    acols = st.columns(min(3, len(artisans)) or 1)
    for i, a in enumerate(artisans[:3]):
        with acols[i % len(acols)]:
            profile = a.artisan_profile
            st.markdown(f"**{a.name}**")
            st.caption(f"{profile.craft_type if profile else 'Traditional Craft'} · {profile.location if profile else 'India'}")
            st.write((profile.bio if profile else "Skilled Indian artisan.")[:140])


def product_details():
    pid = st.session_state.get("selected_product")
    if not pid:
        st.session_state.page = "home"
        st.rerun()

    s = db()
    p = s.get(Product, pid)
    if not p:
        s.close()
        st.error("Product not found.")
        return
    artisan = s.get(User, p.artisan_id)
    profile = s.query(ArtisanProfile).filter_by(user_id=p.artisan_id).first()
    s.close()

    if st.button("← Back"):
        st.session_state.page = "home"
        st.rerun()

    c1, c2 = st.columns([1.1, 1])
    with c1:
        if p.image:
            st.image(BytesIO(p.image), use_container_width=True)
        else:
            st.markdown("## 🧶 Handmade with care")
    with c2:
        st.title(p.name)
        st.subheader(f"₹{p.price:,.0f}")
        st.write(f"⭐ {p.rating:.1f} · {p.stock} in stock")
        st.write(p.description)
        st.write(f"**Material:** {p.material}")
        st.write(f"**Dimensions:** {p.dimensions}")
        st.write(f"**Delivery:** {p.delivery_time}")
        st.info(f"Made by **{artisan.name}**, {profile.location if profile else 'India'}")

        qty = st.number_input("Quantity", 1, max(1, p.stock), 1)
        if st.button("🛒 Add to Cart", type="primary", use_container_width=True):
            add_to_cart(p.id, int(qty))
            st.success("Added to cart!")

        if st.button("⚡ Buy Now", use_container_width=True):
            add_to_cart(p.id, int(qty))
            st.session_state.page = "checkout"
            st.rerun()

    st.subheader("Craft Story")
    st.write(
        "Every CraftConnect purchase supports an artisan's skill, livelihood and cultural heritage. "
        "The product is made in small batches, so natural variations are part of its character."
    )


def add_to_cart(product_id, quantity):
    u = current_user()
    if not u or u.role != "Customer":
        st.error("Please log in as a customer to shop.")
        return
    s = db()
    item = s.query(CartItem).filter_by(customer_id=u.id, product_id=product_id).first()
    if item:
        item.quantity += quantity
    else:
        s.add(CartItem(customer_id=u.id, product_id=product_id, quantity=quantity))
    s.commit()
    s.close()


def cart_page():
    u = current_user()
    st.header("Your Cart")
    s = db()
    items = s.query(CartItem).filter_by(customer_id=u.id).all()
    if not items:
        st.info("Your cart is empty. Explore handcrafted products to get started.")
        s.close()
        return

    total = 0
    for item in items:
        p = s.get(Product, item.product_id)
        if not p:
            continue
        c1, c2, c3, c4 = st.columns([1.2, 3, 1.5, 1])
        with c1:
            if p.image: st.image(BytesIO(p.image), width=100)
        with c2:
            st.markdown(f"**{p.name}**")
            st.caption(p.category)
        with c3:
            qty = st.number_input("Qty", 1, max(1, p.stock), item.quantity, key=f"qty_{item.id}")
            if qty != item.quantity:
                item.quantity = int(qty)
                s.commit()
        with c4:
            st.write(f"₹{p.price * item.quantity:,.0f}")
            if st.button("Remove", key=f"remove_{item.id}"):
                s.delete(item)
                s.commit()
                st.rerun()
        total += p.price * item.quantity

    st.divider()
    st.subheader(f"Total: ₹{total:,.0f}")
    if st.button("Proceed to Checkout", type="primary", use_container_width=True):
        st.session_state.page = "checkout"
        st.rerun()
    s.close()


def checkout_page():
    u = current_user()
    st.header("Checkout")
    s = db()
    items = s.query(CartItem).filter_by(customer_id=u.id).all()
    rows = []
    total = 0
    for item in items:
        p = s.get(Product, item.product_id)
        if p:
            subtotal = p.price * item.quantity
            rows.append((item, p, subtotal))
            total += subtotal

    if not rows:
        s.close()
        st.info("Your cart is empty.")
        return

    with st.form("checkout"):
        address = st.text_area("Delivery Address")
        phone = st.text_input("Contact Number", value=u.phone)
        st.subheader("Order Summary")
        for _, p, subtotal in rows:
            st.write(f"{p.name} × {_[0].quantity if False else ''}")
            st.write(f"₹{subtotal:,.0f}")
        st.markdown(f"### Total: ₹{total:,.0f}")
        st.caption("Demo payment only — no real money will be charged.")
        place = st.form_submit_button("Place Order / Demo Payment", type="primary", use_container_width=True)

    if place:
        if len(address.strip()) < 10:
            st.error("Please enter a complete delivery address.")
        elif len(phone.strip()) < 8:
            st.error("Please enter a valid contact number.")
        else:
            order = Order(customer_id=u.id, total_amount=total, status="New",
                          delivery_address=address.strip(), contact_number=phone.strip())
            s.add(order)
            s.flush()
            for item, p, subtotal in rows:
                if p.stock < item.quantity:
                    st.error(f"Only {p.stock} units of {p.name} are available.")
                    s.rollback()
                    s.close()
                    return
                p.stock -= item.quantity
                s.add(OrderItem(order_id=order.id, product_id=p.id,
                                quantity=item.quantity, price=p.price))
                s.delete(item)
            s.commit()
            order_id = order.id
            s.close()
            st.session_state.confirmed_order = order_id
            st.session_state.page = "confirmation"
            st.rerun()
    else:
        s.close()


def confirmation_page():
    oid = st.session_state.get("confirmed_order")
    st.balloons()
    st.success("🎉 Order placed successfully!")
    st.header("Thank you for supporting Indian artisans.")
    st.metric("Order ID", f"CC-{oid:05d}")
    st.write("Your artisan partner will begin processing the order.")
    if st.button("Continue Shopping", type="primary"):
        st.session_state.page = "home"
        st.rerun()


def order_history():
    u = current_user()
    st.header("Order History")
    s = db()
    orders = s.query(Order).filter_by(customer_id=u.id).order_by(Order.created_at.desc()).all()
    if not orders:
        st.info("No orders yet.")
        s.close()
        return
    for o in orders:
        st.markdown(f"### CC-{o.id:05d} · {o.status}")
        st.caption(f"{o.created_at:%d %b %Y} · ₹{o.total_amount:,.0f}")
        st.write(o.delivery_address)
        st.divider()
    s.close()


def admin_dashboard():
    st.header("Admin Dashboard")
    s = db()
    users = s.query(User).count()
    artisans = s.query(User).filter_by(role="Artisan").count()
    customers = s.query(User).filter_by(role="Customer").count()
    products = s.query(Product).count()
    orders = s.query(Order).count()
    revenue = s.query(func.sum(Order.total_amount)).filter(Order.status == "Delivered").scalar() or 0
    c = st.columns(6)
    vals = [users, artisans, customers, products, orders, f"₹{revenue:,.0f}"]
    labels = ["Users", "Artisans", "Customers", "Products", "Orders", "Revenue"]
    for col, label, value in zip(c, labels, vals):
        with col: metric_card(label, value)

    st.subheader("Reports")
    order_rows = s.query(Order).all()
    if order_rows:
        df = pd.DataFrame([{"Date": o.created_at.date(), "Amount": o.total_amount} for o in order_rows])
        daily = df.groupby("Date")["Amount"].sum()
        st.line_chart(daily)
    s.close()


def admin_artisans():
    st.header("Manage Artisans")
    s = db()
    artisans = s.query(User).filter_by(role="Artisan").all()
    search = st.text_input("Search artisans")
    for a in artisans:
        if search and search.lower() not in f"{a.name} {a.email}".lower():
            continue
        p = a.artisan_profile
        st.markdown(f"**{a.name}** · {a.email}")
        st.caption(f"{p.location if p else 'India'} · {p.craft_type if p else 'Craft'} · {p.experience if p else 0} years")
        st.divider()
    s.close()


def admin_products():
    st.header("Manage Products")
    s = db()
    products = s.query(Product).order_by(Product.created_at.desc()).all()
    search = st.text_input("Search products")
    for p in products:
        if search and search.lower() not in f"{p.name} {p.category} {p.craft_type}".lower():
            continue
        c1, c2 = st.columns([5, 1])
        with c1:
            st.write(f"**{p.name}** · ₹{p.price:,.0f} · {p.category} · Stock {p.stock}")
        with c2:
            if st.button("Remove", key=f"admin_del_{p.id}"):
                s.delete(p)
                s.commit()
                st.rerun()
    s.close()


def admin_orders():
    st.header("Manage Orders")
    s = db()
    status_filter = st.selectbox("Filter", ["All", "New", "Processing", "Shipped", "Delivered", "Cancelled"])
    orders = s.query(Order).order_by(Order.created_at.desc()).all()
    for o in orders:
        if status_filter != "All" and o.status != status_filter:
            continue
        st.markdown(f"**CC-{o.id:05d}** · ₹{o.total_amount:,.0f} · {o.status}")
        new_status = st.selectbox(
            "Status", ["New", "Processing", "Shipped", "Delivered", "Cancelled"],
            index=["New", "Processing", "Shipped", "Delivered", "Cancelled"].index(o.status),
            key=f"admin_status_{o.id}"
        )
        if st.button("Save", key=f"admin_save_{o.id}"):
            o.status = new_status
            s.commit()
            st.rerun()
        st.divider()
    s.close()


def admin_login_allowed(email, password):
    admin_email = os.getenv("ADMIN_EMAIL")
    admin_password = os.getenv("ADMIN_PASSWORD")
    try:
        admin_email = admin_email or st.secrets.get("ADMIN_EMAIL")
        admin_password = admin_password or st.secrets.get("ADMIN_PASSWORD")
    except Exception:
        pass
    return bool(admin_email and admin_password and email.lower() == admin_email.lower()
                and password == admin_password)


def admin_page():
    st.header("Admin Login")
    with st.form("admin_login"):
        email = st.text_input("Admin Email")
        password = st.text_input("Admin Password", type="password")
        go = st.form_submit_button("Login", type="primary")
    if go:
        if admin_login_allowed(email.strip(), password):
            st.session_state.admin = True
            st.session_state.admin_page = "dashboard"
            st.rerun()
        else:
            st.error("Admin credentials are not configured or are incorrect.")


def sidebar_customer():
    u = current_user()
    st.sidebar.markdown("## 🧶 CraftConnect")
    st.sidebar.caption(f"Hi, {u.name}")
    choices = {
        "Home": "home",
        "Cart": "cart",
        "Order History": "orders",
    }
    for label, page in choices.items():
        if st.sidebar.button(label, use_container_width=True):
            st.session_state.page = page
            st.rerun()
    if st.sidebar.button("Logout", use_container_width=True):
        logout()


def sidebar_artisan():
    u = current_user()
    st.sidebar.markdown("## 🧶 CraftConnect")
    st.sidebar.caption(f"Artisan · {u.name}")
    choices = {
        "Dashboard": "home",
        "My Products": "products",
        "Add Product": "add_product",
        "Orders": "artisan_orders",
        "Earnings": "earnings",
        "Profile": "profile",
    }
    for label, page in choices.items():
        if st.sidebar.button(label, use_container_width=True):
            st.session_state.page = page
            st.rerun()
    if st.sidebar.button("Logout", use_container_width=True):
        logout()


def sidebar_admin():
    st.sidebar.markdown("## 🛡️ Admin")
    choices = {
        "Dashboard": "dashboard",
        "Manage Artisans": "artisans",
        "Manage Products": "admin_products",
        "Manage Orders": "admin_orders",
    }
    for label, page in choices.items():
        if st.sidebar.button(label, use_container_width=True):
            st.session_state.admin_page = page
            st.rerun()
    if st.sidebar.button("Logout"):
        st.session_state.pop("admin", None)
        st.rerun()


# ------------------------- App entry -------------------------

init_demo_data()

if "page" not in st.session_state:
    st.session_state.page = "home"

u = current_user()

if st.session_state.get("admin"):
    sidebar_admin()
    ap = st.session_state.get("admin_page", "dashboard")
    if ap == "dashboard": admin_dashboard()
    elif ap == "artisans": admin_artisans()
    elif ap == "admin_products": admin_products()
    elif ap == "admin_orders": admin_orders()
elif not u:
    login_page()
    st.markdown("---")
    st.caption("CraftConnect prototype · Connecting Crafts to the World")
else:
    if u.role == "Artisan":
        sidebar_artisan()
        page = st.session_state.page
        if page == "home": artisan_home(u)
        elif page == "profile": artisan_profile(u)
        elif page == "add_product": add_product()
        elif page == "products": artisan_products(u)
        elif page == "artisan_orders": artisan_orders(u)
        elif page == "earnings": artisan_earnings(u)
    else:
        sidebar_customer()
        page = st.session_state.page
        if page == "home": customer_home()
        elif page == "product": product_details()
        elif page == "cart": cart_page()
        elif page == "checkout": checkout_page()
        elif page == "confirmation": confirmation_page()
        elif page == "orders": order_history()

# Small admin entry point
with st.sidebar.expander("Admin"):
    if st.button("Open Admin Login"):
        st.session_state.page = "admin_login"
        st.session_state.pop("user_id", None)
        st.rerun()

if st.session_state.get("page") == "admin_login" and not st.session_state.get("admin"):
    admin_page()
