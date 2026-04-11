namespace KingdomCome.Supabase
{
    public static class SupabaseConfig
    {
        public const string ProjectUrl = "https://diyimabdmsjykvitomgd.supabase.co";
        public const string AnonKey    = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpeWltYWJkbXNqeWt2aXRvbWdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MDYyMDgsImV4cCI6MjA4NzA4MjIwOH0.YbDq_1zLli12RY10EFi6yihhlzSYc8oNcUvirN9qp-Q";

        public static string RestUrl     => $"{ProjectUrl}/rest/v1";
        public static string AuthUrl     => $"{ProjectUrl}/auth/v1";
        public static string StorageUrl  => $"{ProjectUrl}/storage/v1";
        public static string RealtimeUrl => $"wss://diyimabdmsjykvitomgd.supabase.co/realtime/v1";
    }
}
