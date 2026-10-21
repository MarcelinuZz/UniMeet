import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Resetting UniMeet database: removing all mock events, relations, and chats...');

  // 1. Wipe all existing data completely
  await prisma.directMessage.deleteMany({});
  await prisma.friendship.deleteMany({});
  await prisma.pollVote.deleteMany({});
  await prisma.pollOption.deleteMany({});
  await prisma.poll.deleteMany({});
  await prisma.message.deleteMany({});
  await prisma.eventParticipant.deleteMany({});
  await prisma.event.deleteMany({});
  await prisma.notification.deleteMany({});
  await prisma.sponsorship.deleteMany({});
  await prisma.user.deleteMany({});

  const defaultPassword = await bcrypt.hash('BinusPass123!', 10);

  // 2. Create strictly the 2 real student accounts (0 events, 0 relations, 0 chats)
  const melvin = await prisma.user.create({
    data: {
      email: 'melvin.goh@binus.ac.id',
      password: defaultPassword,
      name: 'Melvin Goh',
      nim: '2802436181',
      major: 'Cyber Security',
      batch: "Cyber Sec '24",
      campus: 'BINUS Anggrek Campus',
      bio: 'Cyber Security student, CTF competitor, Valorant squad lead & Fore Coffee regular.',
      avatarInitials: 'MG',
      isVerified: true,
      satPoints: 110,
      gpa: 3.85,
      reputation: 4.9,
      interests: ['Cyber Security', 'Valorant', 'Fore Coffee', 'Offensive Security'],
    },
  });

  const marcelinus = await prisma.user.create({
    data: {
      email: 'marcelinus.oey@binus.ac.id',
      password: defaultPassword,
      name: 'Marcelinus Wijaya Oey',
      nim: '2602194831',
      major: 'Computer Science',
      batch: "CS '24",
      campus: 'BINUS Anggrek Campus',
      bio: 'Cloud architecture & Flutter engineer, badminton sparring player & study group host.',
      avatarInitials: 'MW',
      isVerified: true,
      isPremium: true,
      satPoints: 125,
      gpa: 3.9,
      reputation: 5.0,
      interests: ['Badminton', 'Flutter Mobile', 'Calculus II', 'Cloud Computing'],
    },
  });

  console.log('✅ UniMeet Clean Slate Ready!');
  console.log(`- Account 1: ${melvin.name} (${melvin.email})`);
  console.log(`- Account 2: ${marcelinus.name} (${marcelinus.email})`);
  console.log('- Events: 0 (Users create real events)');
  console.log('- Relations: 0 (Users send & accept real friend requests)');
  console.log('- Chats: 0 (Real 1-on-1 and event group chats only)');
}

main()
  .catch((e) => {
    console.error('❌ Error seeding clean slate database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
