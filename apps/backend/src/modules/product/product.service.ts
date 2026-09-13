import * as productRepo from './product.repository.js';
import { prisma } from '@/config/database.config.js';
import { NotFoundError } from '@/errors/http.error.js';
import {
  CreateProductDTO,
  UpdateProductDTO,
  ListProductQuery,
  ReplaceRecipeDTO,
} from './product.validator.js';

export const listProducts = async (businessId: string, query: ListProductQuery) => {
  const products = await productRepo.findProductsByBusinessId(businessId, {
    isActive: query.isActive,
    category: query.category,
    search: query.search,
  });

  const allStocks = await prisma.stockItem.findMany({
    where: { businessId },
    select: { id: true, name: true, currentStock: true },
  });

  return products.map((product: any) => {
    let availablePortions = 30; // default jika belum ada resep
    if (product.recipes && product.recipes.length > 0) {
      let minPortions = Infinity;
      for (const recipe of product.recipes) {
        if (recipe.stock && Number(recipe.quantityRequired) > 0) {
          const portions = Math.floor(
            Number(recipe.stock.currentStock) / Number(recipe.quantityRequired)
          );
          if (portions < minPortions) {
            minPortions = portions;
          }
        }
      }
      if (minPortions !== Infinity) {
        availablePortions = Math.max(0, minPortions);
      }
    } else {
      const match = allStocks.find(
        (s) => s.name.trim().toLowerCase() === product.name.trim().toLowerCase()
      );
      if (match) {
        availablePortions = Math.max(0, Math.floor(Number(match.currentStock)));
      }
    }

    return {
      ...product,
      stock: availablePortions,
      current_stock: availablePortions,
    };
  });
};

export const getProductById = async (id: string, businessId: string) => {
  const product: any = await productRepo.findProductById(id, businessId);
  if (!product) {
    throw new NotFoundError('Produk', 'PRODUCT_NOT_FOUND');
  }

  let availablePortions = 30;
  if (product.recipes && product.recipes.length > 0) {
    let minPortions = Infinity;
    for (const recipe of product.recipes) {
      if (recipe.stock && Number(recipe.quantityRequired) > 0) {
        const portions = Math.floor(
          Number(recipe.stock.currentStock) / Number(recipe.quantityRequired)
        );
        if (portions < minPortions) {
          minPortions = portions;
        }
      }
    }
    if (minPortions !== Infinity) {
      availablePortions = Math.max(0, minPortions);
    }
  } else {
    const match = await prisma.stockItem.findFirst({
      where: {
        businessId,
        name: { equals: product.name.trim(), mode: 'insensitive' },
      },
    });
    if (match) {
      availablePortions = Math.max(0, Math.floor(Number(match.currentStock)));
    }
  }

  return {
    ...product,
    stock: availablePortions,
    current_stock: availablePortions,
  };
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
