/// Local stock photography used when a listing has no usable official banner.
class HackathonCoverAssets {
  HackathonCoverAssets._();

  static const ai = 'assets/images/hackathons/ai-machine-learning.jpg';
  static const coding = 'assets/images/hackathons/coding.jpg';
  static const robotics = 'assets/images/hackathons/robotics.jpg';
  static const space = 'assets/images/hackathons/space-technology.jpg';
  static const cybersecurity = 'assets/images/hackathons/cybersecurity.jpg';
  static const startup = 'assets/images/hackathons/startup-teamwork.jpg';
  static const web = 'assets/images/hackathons/web-development.jpg';
  static const innovation = 'assets/images/hackathons/innovation-team.jpg';

  static String forEvent(String title, String description) {
    final text = '$title $description'.toLowerCase();
    if (_has(text, const ['robot', 'robotics', 'hardware', 'iot', 'embedded'])) {
      return robotics;
    }
    if (_has(text, const ['space', 'satellite', 'nasa', 'orbit', 'astronomy'])) {
      return space;
    }
    if (_has(text, const ['cyber', 'security', 'privacy', 'infosec'])) {
      return cybersecurity;
    }
    if (_has(text, const ['startup', 'entrepreneur', 'venture', 'business'])) {
      return startup;
    }
    if (_has(text, const ['artificial intelligence', 'machine learning', 'ai ', 'llm', 'neural'])) {
      return ai;
    }
    if (_has(text, const ['coding', 'programming', 'developer', 'open source', 'hackathon'])) {
      return coding;
    }
    if (_has(text, const ['web', 'app', 'application', 'software', 'frontend'])) {
      return web;
    }
    return innovation;
  }

  static bool _has(String value, List<String> terms) =>
      terms.any(value.contains);
}
