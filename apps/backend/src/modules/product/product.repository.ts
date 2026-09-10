import { prisma } from '@/config/database.config.js';
import { Product, ProductCategory, Prisma } from '@prisma/client';

export interface CreateProductInput {
  name: string;
  price: number | Prisma.Decimal;
  category: ProductCategory;
  imageUrl?: string | null;
  defaultVariant?: string | null;
  isActive?: boolean;
}

export interface UpdateProductInput {
  name?: string;
  price?: number | Prisma.Decimal;
  category?: ProductCategory;
  imageUrl?: string | null;
  defaultVariant?: string | null;
  isActive?: boolean;
}

export interface RecipeItemInput {
  stockId: string;
  quantityRequired: number;
}

export const findProductsByBusinessId = async (
  businessId: string,
  options?: { isActive?: boolean; category?: ProductCategory; search?: string }
): Promise<Product[]> => {
  const where: Prisma.ProductWhereInput = {
    businessId,
  };

  if (options?.isActive !== undefined) {
    where.isActive = options.isActive;
  }

  if (options?.category) {
    where.category = options.category;
  }

  if (options?.search) {
    where.name = {
      contains: options.search,
      mode: 'insensitive',
    };
  }

  return await prisma.product.findMany({
    where,
    orderBy: { name: 'asc' },
    include: {
      recipes: {
        include: {
          stock: {
            select: {
              id: true,
              name: true,
              unit: true,
              currentStock: true,
            },
          },
        },
      },
    },
  });
};

export const findProductById = async (
  id: string,
  businessId: string
): Promise<Product | null> => {
  return await prisma.product.findFirst({
    where: { id, businessId },
    include: {
      recipes: {
        include: {
          stock: true,
        },
      },
    },
  });
};

export const createProduct = async (
  businessId: string,
  data: CreateProductInput
): Promise<Product> => {
  return await prisma.product.create({
    data: {
      businessId,
      name: data.name,
      price: data.price,
      category: data.category,
      imageUrl: data.imageUrl ?? null,
      defaultVariant: data.defaultVariant ?? 'Regular',
      isActive: data.isActive ?? true,
    },
  });
};

export const updateProduct = async (
  id: string,
  businessId: string,
  data: UpdateProductInput
): Promise<Product> => {
  return await prisma.product.update({
    where: { id, businessId },
    data,
  });
};

export const deleteProduct = async (
  id: string,
  businessId: string
): Promise<Product> => {
  return await prisma.product.update({
    where: { id, businessId },
    data: { isActive: false },
  });
};

export const findRecipeByProductId = async (
  productId: string,
  businessId: string
) => {
  const product = await prisma.product.findFirst({
    where: { id: productId, businessId },
    select: {
      id: true,
      name: true,
      recipes: {
        include: {
          stock: {
            select: {
              id: true,
              name: true,
              unit: true,
              currentStock: true,
              costPerUnit: true,
            },
          },
        },
      },
    },
  });

  return product?.recipes ?? null;
};

export const replaceProductRecipe = async (
  productId: string,
  businessId: string,
  items: RecipeItemInput[]
) => {
  return await prisma.$transaction(async (tx) => {
    // Pastikan produk milik bisnis ini
    const product = await tx.product.findFirst({
      where: { id: productId, businessId },
    });
    if (!product) throw new Error('Product not found in this business');

    // Hapus resep lama
    await tx.productRecipe.deleteMany({
      where: { productId },
    });

    if (items.length === 0) return [];

    // Buat resep baru
    await tx.productRecipe.createMany({
      data: items.map((item) => ({
        productId,
        stockId: item.stockId,
        quantityRequired: item.quantityRequired,
      })),
    });

    return await tx.productRecipe.findMany({
      where: { productId },
      include: {
        stock: true,
      },
    });
  });
};
