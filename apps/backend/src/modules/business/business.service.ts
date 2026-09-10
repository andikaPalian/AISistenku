import * as businessRepo from './business.repository.js';
import * as userRepo from '../user/user.repository.js';
import { BusinessRole } from '@prisma/client';
import { ConflictError, ForbiddenError, NotFoundError } from '@/errors/http.error.js';
import { CreateBusinessInput, UpdateBusinessInput, AddMemberInput } from './business.validator.js';

export const listUserBusinesses = async (userId: string) => {
  const memberships = await businessRepo.findBusinessesByUserId(userId);
  return memberships.map((m) => ({
    ...m.business,
    role: m.role,
    memberId: m.id,
  }));
};

export const createBusiness = async (data: CreateBusinessInput, userId: string) => {
  const business = await businessRepo.createBusinessWithOwner(data, userId);
  return {
    ...business,
    role: BusinessRole.OWNER,
  };
};

const assertOwner = async (businessId: string, userId: string) => {
  const membership = await businessRepo.findBusinessMembership(businessId, userId);
  if (!membership || membership.role !== BusinessRole.OWNER) {
    throw new ForbiddenError(
      'Hanya pemilik (OWNER) yang dapat melakukan tindakan ini pada bisnis.',
      'OWNER_REQUIRED'
    );
  }
  return membership;
};

const assertMember = async (businessId: string, userId: string) => {
  const membership = await businessRepo.findBusinessMembership(businessId, userId);
  if (!membership) {
    throw new ForbiddenError(
      'Anda bukan anggota dari bisnis ini.',
      'BUSINESS_ACCESS_DENIED'
    );
  }
  return membership;
};

export const updateBusiness = async (
  businessId: string,
  data: UpdateBusinessInput,
  userId: string
) => {
  await assertOwner(businessId, userId);
  const business = await businessRepo.findBusinessById(businessId);
  if (!business) {
    throw new NotFoundError('Bisnis', 'BUSINESS_NOT_FOUND');
  }

  return await businessRepo.updateBusiness(businessId, data);
};

export const listBusinessMembers = async (businessId: string, userId: string) => {
  await assertMember(businessId, userId);
  return await businessRepo.findBusinessMembers(businessId);
};

export const addBusinessMember = async (
  businessId: string,
  input: AddMemberInput,
  userId: string
) => {
  await assertOwner(businessId, userId);

  const targetUser = await userRepo.findUserByEmail(input.email);
  if (!targetUser) {
    throw new NotFoundError(
      `Pengguna dengan email ${input.email} tidak ditemukan. Pengguna harus terdaftar terlebih dahulu.`,
      'USER_NOT_FOUND'
    );
  }

  const existingMember = await businessRepo.findBusinessMembership(businessId, targetUser.id);
  if (existingMember) {
    throw new ConflictError('Pengguna sudah menjadi anggota dari bisnis ini.', 'MEMBER_ALREADY_EXISTS');
  }

  return await businessRepo.addBusinessMember(businessId, targetUser.id, input.role);
};

export const updateBusinessMemberRole = async (
  businessId: string,
  memberId: string,
  role: BusinessRole,
  userId: string
) => {
  await assertOwner(businessId, userId);

  const member = await businessRepo.findMemberById(memberId);
  if (!member || member.businessId !== businessId) {
    throw new NotFoundError('Anggota bisnis tidak ditemukan.', 'MEMBER_NOT_FOUND');
  }

  return await businessRepo.updateBusinessMemberRole(memberId, role);
};

export const removeBusinessMember = async (
  businessId: string,
  memberId: string,
  userId: string
) => {
  await assertOwner(businessId, userId);

  const member = await businessRepo.findMemberById(memberId);
  if (!member || member.businessId !== businessId) {
    throw new NotFoundError('Anggota bisnis tidak ditemukan.', 'MEMBER_NOT_FOUND');
  }

  if (member.userId === userId) {
    throw new ConflictError('Anda tidak dapat menghapus diri Anda sendiri sebagai Owner.', 'CANNOT_REMOVE_SELF');
  }

  await businessRepo.deleteBusinessMember(memberId);
};
