class UserProfile {
  final String id;
  final String name;
  final int age;
  final String bio;
  final String imageUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrl,
  });

  static List<UserProfile> getDummyProfiles() {
    return [
      UserProfile(
        id: '1',
        name: 'Sarah Johnson',
        age: 28,
        bio: 'Love hiking and outdoor adventures. Coffee enthusiast.',
        imageUrl: 'https://picsum.photos/seed/user1/400/600',
      ),
      UserProfile(
        id: '2',
        name: 'Mike Chen',
        age: 32,
        bio: 'Tech entrepreneur. Foodie. Travel addict.',
        imageUrl: 'https://picsum.photos/seed/user2/400/600',
      ),
      UserProfile(
        id: '3',
        name: 'Emma Wilson',
        age: 26,
        bio: 'Yoga instructor. Plant mom. Beach lover.',
        imageUrl: 'https://picsum.photos/seed/user3/400/600',
      ),
      UserProfile(
        id: '4',
        name: 'David Martinez',
        age: 30,
        bio: 'Musician. Dog person. Always up for an adventure.',
        imageUrl: 'https://picsum.photos/seed/user4/400/600',
      ),
      UserProfile(
        id: '5',
        name: 'Lisa Thompson',
        age: 29,
        bio: 'Artist. Book lover. Wine enthusiast.',
        imageUrl: 'https://picsum.photos/seed/user5/400/600',
      ),
      UserProfile(
        id: '6',
        name: 'James Anderson',
        age: 35,
        bio: 'Fitness coach. Mountain biker. Cooking hobbyist.',
        imageUrl: 'https://picsum.photos/seed/user6/400/600',
      ),
      UserProfile(
        id: '7',
        name: 'Sofia Rodriguez',
        age: 27,
        bio: 'Photographer. World traveler. Coffee connoisseur.',
        imageUrl: 'https://picsum.photos/seed/user7/400/600',
      ),
      UserProfile(
        id: '8',
        name: 'Ryan Kim',
        age: 31,
        bio: 'Software developer. Gamer. Sushi lover.',
        imageUrl: 'https://picsum.photos/seed/user8/400/600',
      ),
      UserProfile(
        id: '9',
        name: 'Olivia Brown',
        age: 25,
        bio: 'Dance teacher. Movie buff. Cat person.',
        imageUrl: 'https://picsum.photos/seed/user9/400/600',
      ),
      UserProfile(
        id: '10',
        name: 'Alex Taylor',
        age: 33,
        bio: 'Architect. Jazz enthusiast. Urban explorer.',
        imageUrl: 'https://picsum.photos/seed/user10/400/600',
      ),
    ];
  }
}