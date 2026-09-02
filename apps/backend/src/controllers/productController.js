import { supabase } from '../lib/supabase.js';
import { store, DEMO_USER_ID } from '../lib/store.js';

export const getProducts = async (req, res, next) => {
  try {
    const { category } = req.query;
    const userId = req.user?.user_id || DEMO_USER_ID;

    if (supabase) {
      let query = supabase.from('products').select('*');
      if (userId) {
        query = query.eq('user_id', userId);
      }
      if (category && category !== 'All') {
        query = query.eq('category', category);
      }
      const { data, error } = await query;
      if (!error && data) {
        return res.json({ products: data });
      }
    }

    let items = store.products.filter((p) => p.user_id === userId);
    if (category && category !== 'All') {
      items = items.filter((p) => p.category.toLowerCase() === category.toLowerCase());
    }

    return res.json({ products: items });
  } catch (err) {
    next(err);
  }
};

export const createProduct = async (req, res, next) => {
  try {
    const { name, price, category, default_variant, image_url, code, stock, min_stock, unit } = req.body;
    if (!name || !price || !category) {
      return res.status(400).json({ error: 'Name, price, and category are required' });
    }

    const userId = req.user?.user_id || DEMO_USER_ID;
    const newProd = {
      product_id: `prod-${Date.now()}`,
      user_id: userId,
      name,
      price: Number(price),
      category,
      default_variant: default_variant || 'Regular',
      image_url: image_url || null,
      code: code || `PRD-${Date.now().toString().slice(-4)}`,
      current_stock: stock !== undefined ? Number(stock) : 0,
      min_stock: min_stock !== undefined ? Number(min_stock) : 0,
      unit: unit || 'cup',
      created_at: new Date().toISOString(),
    };

    if (supabase) {
      const dbProd = {
        product_id: newProd.product_id,
        user_id: newProd.user_id,
        name: newProd.name,
        price: newProd.price,
        category: newProd.category,
        default_variant: newProd.default_variant,
        image_url: newProd.image_url,
        code: newProd.code,
        created_at: newProd.created_at
      };
      
      const { data, error } = await supabase.from('products').insert([dbProd]).select().single();
      
      // Auto-create stock item to link with this product
      const dbStock = {
        stock_id: `stock-${newProd.product_id}`,
        user_id: newProd.user_id,
        name: newProd.name,
        category: newProd.category,
        current_stock: newProd.current_stock,
        min_stock: newProd.min_stock,
        unit: newProd.unit,
        cost_per_unit: Math.floor(newProd.price * 0.4),
        supplier: 'Internal',
        created_at: newProd.created_at,
        updated_at: newProd.created_at
      };
      await supabase.from('stock_items').insert([dbStock]).catch(() => {});
      store.stockItems.unshift(dbStock);

      if (!error && data) {
        // Return full merged data to frontend
        return res.status(201).json({ product: { ...data, current_stock: newProd.current_stock, min_stock: newProd.min_stock, unit: newProd.unit } });
      }
      if (error) console.error("Error inserting product:", error);
    }

    store.products.unshift(newProd);
    return res.status(201).json({ product: newProd });
  } catch (err) {
    next(err);
  }
};

export const updateProduct = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, price, category, default_variant, image_url } = req.body;

    if (supabase) {
      const { data, error } = await supabase
        .from('products')
        .update({ name, price, category, default_variant, image_url })
        .eq('product_id', id)
        .select()
        .single();
      if (!error && data) {
        return res.json({ product: data });
      }
    }

    const idx = store.products.findIndex((p) => p.product_id === id);
    if (idx === -1) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const updated = {
      ...store.products[idx],
      name: name ?? store.products[idx].name,
      price: price ? Number(price) : store.products[idx].price,
      category: category ?? store.products[idx].category,
      default_variant: default_variant ?? store.products[idx].default_variant,
      image_url: image_url ?? store.products[idx].image_url,
    };
    store.products[idx] = updated;

    return res.json({ product: updated });
  } catch (err) {
    next(err);
  }
};

export const deleteProduct = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (supabase) {
      await supabase.from('products').delete().eq('product_id', id);
    }

    store.products = store.products.filter((p) => p.product_id !== id);
    return res.json({ message: 'Product deleted successfully', product_id: id });
  } catch (err) {
    next(err);
  }
};
