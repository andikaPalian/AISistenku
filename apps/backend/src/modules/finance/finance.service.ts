import * as financeRepo from './finance.repository.js';
import { NotFoundError } from '@/errors/http.error.js';
import { CreateFinanceDTO, ListFinanceQuery } from './finance.validator.js';

export const createTransaction = async (
  businessId: string,
  userId: string | null,
  input: CreateFinanceDTO
) => {
  return await financeRepo.createFinanceTransaction(businessId, {
    ...input,
    userId,
  });
};

export const listTransactions = async (
  businessId: string,
  query: ListFinanceQuery
) => {
  const page = query.page ?? 1;
  const limit = query.limit ?? 50;
  const offset = (page - 1) * limit;

  const fromDate = query.from ? new Date(query.from) : undefined;
  const toDate = query.to ? new Date(query.to) : undefined;
  const searchQuery = query.query || query.q;

  const { transactions, total } = await financeRepo.findFinanceTransactionsByBusinessId(
    businessId,
    {
      type: query.type,
      category: query.category,
      query: searchQuery,
      from: fromDate,
      to: toDate,
      limit,
      offset,
    }
  );

  return {
    transactions,
    meta: {
      total,
      page,
      limit,
      hasNextPage: offset + transactions.length < total,
    },
  };
};

export const deleteTransaction = async (id: string, businessId: string) => {
  const tx = await financeRepo.findFinanceTransactionById(id, businessId);
  if (!tx) {
    throw new NotFoundError('Transaksi keuangan', 'TRANSACTION_NOT_FOUND');
  }
  return await financeRepo.deleteFinanceTransaction(id, businessId);
};
