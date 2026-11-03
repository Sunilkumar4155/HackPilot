import '../models/hackathon.dart';
import 'hackathon_cover_assets.dart';

/// Provides realistic, curated, high-resolution photography for hackathons
/// across different technical domains, ensuring distinct images per event.
class HackathonImageHelper {
  HackathonImageHelper._();

  // Curated, verified, high-quality Unsplash photography for each domain.
  // Each URL is optimized with auto=format&fit=crop&w=800&q=80 for fast CDN delivery and CORS support.

  static const List<String> _aiImages = [
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=800&q=80', // Futuristic AI intelligence
    'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?auto=format&fit=crop&w=800&q=80', // Deep neural networks
    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80', // Abstract AI algorithms
    'https://images.unsplash.com/photo-1555255707-c07966088b7b?auto=format&fit=crop&w=800&q=80', // AI computer vision & data
    'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?auto=format&fit=crop&w=800&q=80', // Cyber code & matrix algorithms
  ];

  static const List<String> _webDevImages = [
    'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=800&q=80', // Modern developer dual-screen desk
    'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?auto=format&fit=crop&w=800&q=80', // Web UI & frontend architecture
    'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800&q=80', // Programmer typing JavaScript/HTML
    'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=80', // Full stack developer workspace
    'https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&w=800&q=80', // Code syntax on screen
  ];

  static const List<String> _cybersecurityImages = [
    'https://images.unsplash.com/photo-1563986768609-322da13575f3?auto=format&fit=crop&w=800&q=80', // Cyber defense shield & telemetry
    'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=800&q=80', // Cybersecurity server operations center
    'https://images.unsplash.com/photo-1510511459019-5dda7724fd87?auto=format&fit=crop&w=800&q=80', // Cryptography & encryption keys
    'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?auto=format&fit=crop&w=800&q=80', // Penetration testing & binary data
  ];

  static const List<String> _roboticsImages = [
    'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?auto=format&fit=crop&w=800&q=80', // Robotic arm in engineering lab
    'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=800&q=80', // Robotic hardware engineering
    'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=800&q=80', // Microcontroller circuit boards & IoT
    'https://images.unsplash.com/photo-1563770660941-20978e870e26?auto=format&fit=crop&w=800&q=80', // Automation sensors & engineering
  ];

  static const List<String> _blockchainImages = [
    'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?auto=format&fit=crop&w=800&q=80', // Web3 blockchain nodes
    'https://images.unsplash.com/photo-1621416894569-0f39ed31d247?auto=format&fit=crop&w=800&q=80', // Cryptocurrency decentralized networks
    'https://images.unsplash.com/photo-1642543492481-44e81e3914a7?auto=format&fit=crop&w=800&q=80', // Smart contracts & ledger tech
  ];

  static const List<String> _cloudImages = [
    'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?auto=format&fit=crop&w=800&q=80', // Hyperscale data center corridor
    'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=800&q=80', // Cloud infrastructure & global network
    'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=800&q=80', // Server racks & cloud computing
  ];

  static const List<String> _startupImages = [
    'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80', // Startup founders collaborating on laptops
    'https://images.unsplash.com/photo-1531482615713-2afd69097998?auto=format&fit=crop&w=800&q=80', // Product agile sprint & brainstorming
    'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?auto=format&fit=crop&w=800&q=80', // Pitching ideas in modern tech incubator
    'https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&w=800&q=80', // Diverse hackathon team brainstorming
  ];

  static const List<String> _hackathonImages = [
    'https://images.unsplash.com/photo-1515187029135-18ee286d815b?auto=format&fit=crop&w=800&q=80', // Hackathon auditorium filled with hackers
    'https://images.unsplash.com/photo-1528605248644-14dd04022da1?auto=format&fit=crop&w=800&q=80', // Teams collaborating overnight
    'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=800&q=80', // Hackathon project building sprint
    'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=800&q=80', // Tech conference & hack sprint
  ];

  static const List<String> _spaceImages = [
    'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=800&q=80', // Earth from orbit satellite
    'https://images.unsplash.com/photo-1446776877081-d282a0f896e2?auto=format&fit=crop&w=800&q=80', // Orbital space station
    'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=800&q=80', // Rocket science launch
  ];

  static const List<String> _climateImages = [
    'https://images.unsplash.com/photo-1497435334941-8c899ee9e8e9?auto=format&fit=crop&w=800&q=80', // Clean energy wind turbines & sun
    'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?auto=format&fit=crop&w=800&q=80', // Sustainability and green tech
  ];

  /// Returns a realistic, high-quality image URL for a given hackathon.
  /// If the hackathon already has a valid HTTPS imageUrl, returns it.
  /// Otherwise, selects a category-specific realistic photo seeded by event id
  /// so that different hackathons get distinct, non-repetitive imagery.
  static String resolveImageUrl(Hackathon event) {
    final customUrl = event.imageUrl.trim();
    if (customUrl.isNotEmpty &&
        (customUrl.startsWith('http://') || customUrl.startsWith('https://'))) {
      return customUrl;
    }
    return getRealisticImageFor(event.id, event.title, event.description);
  }

  /// Picks a distinct, domain-specific image from our curated collection
  /// based on text analysis and event hash.
  static String getRealisticImageFor(String id, String title, String description) {
    final text = '$title $description'.toLowerCase();
    final seed = (id.hashCode ^ title.hashCode).abs();

    if (_has(text, ['robot', 'robotics', 'hardware', 'iot', 'embedded', 'sensor', 'arduino'])) {
      return _roboticsImages[seed % _roboticsImages.length];
    }
    if (_has(text, ['space', 'satellite', 'nasa', 'orbit', 'astronomy', 'aerospace', 'cosmos'])) {
      return _spaceImages[seed % _spaceImages.length];
    }
    if (_has(text, ['cyber', 'security', 'infosec', 'privacy', 'hacker', 'defense', 'vulnerability'])) {
      return _cybersecurityImages[seed % _cybersecurityImages.length];
    }
    if (_has(text, ['blockchain', 'web3', 'crypto', 'nft', 'ethereum', 'solana', 'defi', 'decentralized'])) {
      return _blockchainImages[seed % _blockchainImages.length];
    }
    if (_has(text, ['cloud', 'aws', 'azure', 'gcp', 'devops', 'kubernetes', 'docker', 'infrastructure', 'server'])) {
      return _cloudImages[seed % _cloudImages.length];
    }
    if (_has(text, ['climate', 'sustainability', 'environment', 'green', 'energy', 'carbon', 'eco'])) {
      return _climateImages[seed % _climateImages.length];
    }
    if (_has(text, ['startup', 'founder', 'venture', 'entrepreneur', 'business', 'pitch', 'incubator'])) {
      return _startupImages[seed % _startupImages.length];
    }
    if (_has(text, ['ai', 'machine learning', 'artificial intelligence', 'llm', 'deep learning', 'neural', 'gpt', 'vision', 'nlp'])) {
      return _aiImages[seed % _aiImages.length];
    }
    if (_has(text, ['web', 'frontend', 'backend', 'fullstack', 'react', 'javascript', 'html', 'css', 'flutter', 'mobile', 'app'])) {
      return _webDevImages[seed % _webDevImages.length];
    }

    // Default to realistic coding competition / hackathon photography
    return _hackathonImages[seed % _hackathonImages.length];
  }

  /// Returns the corresponding local asset path for safe offline fallback.
  static String getLocalAssetFallback(String title, String description) {
    return HackathonCoverAssets.forEvent(title, description);
  }

  static bool _has(String value, List<String> terms) =>
      terms.any(value.contains);
}
