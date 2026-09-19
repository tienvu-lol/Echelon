import { StyleSheet, View, Text } from 'react-native';

export default function ProfileScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Profile</Text>
      <Text style={styles.subtitle}>Your student profile</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Profile Setup</Text>
        <Text style={styles.cardText}>
          Upload your resume or fill in your details to get personalized
          opportunity recommendations.
        </Text>
        <View style={styles.fieldPlaceholder}>
          <Text style={styles.fieldLabel}>Major</Text>
          <Text style={styles.fieldValue}>Not set</Text>
        </View>
        <View style={styles.fieldPlaceholder}>
          <Text style={styles.fieldLabel}>Graduation Year</Text>
          <Text style={styles.fieldValue}>Not set</Text>
        </View>
        <View style={styles.fieldPlaceholder}>
          <Text style={styles.fieldLabel}>Skills</Text>
          <Text style={styles.fieldValue}>None added</Text>
        </View>
        <View style={styles.fieldPlaceholder}>
          <Text style={styles.fieldLabel}>Interests</Text>
          <Text style={styles.fieldValue}>None added</Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#333',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 24,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 12,
    color: '#333',
  },
  cardText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 20,
    lineHeight: 20,
  },
  fieldPlaceholder: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  fieldLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  fieldValue: {
    fontSize: 14,
    color: '#999',
  },
});
