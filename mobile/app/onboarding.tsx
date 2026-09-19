import { StyleSheet, View, Text, Pressable } from 'react-native';
import { router } from 'expo-router';

export default function OnboardingScreen() {
  return (
    <View style={styles.container}>
      <View style={styles.hero}>
        <Text style={styles.logo}>🎯</Text>
        <Text style={styles.title}>Echelon</Text>
        <Text style={styles.tagline}>
          Discover campus opportunities{"\n"}tailored just for you
        </Text>
      </View>

      <View style={styles.features}>
        <Text style={styles.feature}>📄 Upload your resume</Text>
        <Text style={styles.feature}>🤖 AI-powered matching</Text>
        <Text style={styles.feature}>👆 Swipe to discover</Text>
        <Text style={styles.feature}>📌 Save what matters</Text>
      </View>

      <Pressable
        style={styles.button}
        onPress={() => router.replace('/(tabs)')}
      >
        <Text style={styles.buttonText}>Get Started</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 40,
    justifyContent: 'space-between',
  },
  hero: {
    alignItems: 'center',
    marginTop: 80,
  },
  logo: {
    fontSize: 64,
    marginBottom: 16,
  },
  title: {
    fontSize: 36,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 12,
  },
  tagline: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    lineHeight: 24,
  },
  features: {
    gap: 16,
  },
  feature: {
    fontSize: 16,
    color: '#444',
    paddingVertical: 8,
  },
  button: {
    backgroundColor: '#861F41',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 40,
  },
  buttonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
});
