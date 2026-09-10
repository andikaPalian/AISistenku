import { Request, Response } from 'express';
import * as productService from './product.service.js';
import { sendCreated, sendEmptySuccess, sendSuccess } from '@/http/response.js';
import { ListProductQuery } from './product.validator.js';

export const listProducts = async (req: Request, res: Response): Promise<void> => {
  const query = req.query as unknown as ListProductQuery;
  const products = await productService.listProducts(req.businessId!, query);
  
  res.status(200).json({
    success: true,
    message: 'Daftar produk berhasil diambil',
    data: products,
    products, // interoperability with frontend prototype
  });
};

export const getProduct = async (req: Request, res: Response): Promise<void> => {
  const product = await productService.getProductById(req.params.id as string, req.businessId!);
  sendSuccess(res, product, 'Detail produk berhasil diambil');
};

export const createProduct = async (req: Request, res: Response): Promise<void> => {
  const product = await productService.createProduct(req.businessId!, req.body);
  sendCreated(res, product, 'Produk berhasil dibuat');
};

export const updateProduct = async (req: Request, res: Response): Promise<void> => {
  const product = await productService.updateProduct(
    req.params.id as string,
    req.businessId!,
    req.body
  );
  sendSuccess(res, product, 'Produk berhasil diperbarui');
};

export const deleteProduct = async (req: Request, res: Response): Promise<void> => {
  await productService.deleteProduct(req.params.id as string, req.businessId!);
  sendEmptySuccess(res, 'Produk berhasil dinonaktifkan');
};

export const getRecipe = async (req: Request, res: Response): Promise<void> => {
  const recipe = await productService.getProductRecipe(req.params.id as string, req.businessId!);
  sendSuccess(res, recipe, 'Resep produk berhasil diambil');
};

export const setRecipe = async (req: Request, res: Response): Promise<void> => {
  const recipe = await productService.setProductRecipe(
    req.params.id as string,
    req.businessId!,
    req.body
  );
  sendSuccess(res, recipe, 'Resep produk berhasil disimpan');
};
