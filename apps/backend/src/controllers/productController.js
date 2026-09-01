import { supabase } from '../lib/supabase.js';
import { store } from '../lib/store.js';

export const getProducts = async (req, res, next) => {
  try {
    const { category } = req.query;

    if (supabase) {
      let query = supabase.from('products').select('*');
      if (category && category !== 'All') {
        query = query.eq('category', category);
      }
      const { data, error } = await query;
      if (!error && data && data.length > 0) {
        return res.json({ products: data });
      }
    }

    let items = store.products;
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
    const { name, price, category, default_variant, image_url } = req.body;
    if (!name || !price || !category) {
      return res.status(400).json({ error: 'Name, price, and category are required' });
    }

    const newProd = {
      product_id: `prod-${Date.now()}`,
      name,
      price: Number(price),
      category,
      default_variant: default_variant || 'Regular',
      image_url: image_url || null,
      created_at: new Date().toISOString(),
    };

    if (supabase) {
      const { data, error } = await supabase.from('products').insert([newProd]).select().single();
      if (!error && data) {
        return res.status(201).json({ product: data });
      }
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
