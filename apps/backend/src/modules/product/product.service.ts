import * as productRepo from './product.repository.js';
import { NotFoundError } from '@/errors/http.error.js';
import {
  CreateProductDTO,
  UpdateProductDTO,
  ListProductQuery,
  ReplaceRecipeDTO,
} from './product.validator.js';

export const listProducts = async (businessId: string, query: ListProductQuery) => {
  return await productRepo.findProductsByBusinessId(businessId, {
    isActive: query.isActive,
    category: query.category,
    search: query.search,
  });
};

export const getProductById = async (id: string, businessId: string) => {
  const product = await productRepo.findProductById(id, businessId);
  if (!product) {
    throw new NotFoundError('Produk', 'PRODUCT_NOT_FOUND');
  }
  return product;
};

export const createProduct = async (businessId: string, input: CreateProductDTO) => {
  return await productRepo.createProduct(businessId, input);
};

export const updateProduct = async (
  id: string,
  businessId: string,
  input: UpdateProductDTO
) => {
  await getProductById(id, businessId);
  return await productRepo.updateProduct(id, businessId, input);
};

export const deleteProduct = async (id: string, businessId: string) => {
  await getProductById(id, businessId);
  return await productRepo.deleteProduct(id, businessId);
};

export const getProductRecipe = async (productId: string, businessId: string) => {
  await getProductById(productId, businessId);
  const recipes = await productRepo.findRecipeByProductId(productId, businessId);
  return recipes ?? [];
};

export const setProductRecipe = async (
  productId: string,
  businessId: string,
  input: ReplaceRecipeDTO
) => {
  await getProductById(productId, businessId);
  return await productRepo.replaceProductRecipe(productId, businessId, input.items);
};
