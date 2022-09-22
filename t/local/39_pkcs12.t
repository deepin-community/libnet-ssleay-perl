use lib 'inc';

use Net::SSLeay;
use Test::Net::SSLeay qw( data_file_path initialise_libssl );

plan tests => 19;

initialise_libssl();

# Encrypted PKCS#12 archive, no chain:
my $filename1          = data_file_path('simple-cert.enc.p12');
my $filename1_password = 'test';

# Encrypted PKCS#12 archive, full chain:
my $filename2          = data_file_path('simple-cert.certchain.enc.p12');
my $filename2_password = 'test';

# PKCS#12 archive, no chain:
my $filename3 = data_file_path('simple-cert.p12');

{
  my($privkey, $cert, @cachain) = Net::SSLeay::P_PKCS12_load_file($filename1, 1, $filename1_password);
  ok($privkey, '$privkey [1]');
  ok($cert, '$cert [1]');
  is(scalar(@cachain), 0, 'size of @cachain [1]');
  my $subj_name = Net::SSLeay::X509_get_subject_name($cert);
  is(Net::SSLeay::X509_NAME_oneline($subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=simple-cert.net-ssleay.example', "X509_NAME_oneline [1]");
}

{
  my($privkey, $cert, @cachain) = Net::SSLeay::P_PKCS12_load_file($filename2, 1, $filename2_password);
  ok($privkey, '$privkey [2]');
  ok($cert, '$cert [2]');
  is(scalar(@cachain), 2, 'size of @cachain [2]');
  my $subj_name = Net::SSLeay::X509_get_subject_name($cert);
  my $ca1_subj_name = Net::SSLeay::X509_get_subject_name($cachain[0]);
  my $ca2_subj_name = Net::SSLeay::X509_get_subject_name($cachain[1]);
  is(Net::SSLeay::X509_NAME_oneline($subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=simple-cert.net-ssleay.example', "X509_NAME_oneline [2/1]");
  like(Net::SSLeay::X509_NAME_oneline($ca1_subj_name), qr/C=.*CN=.*/, "X509_NAME_oneline [2/2]");
  like(Net::SSLeay::X509_NAME_oneline($ca2_subj_name), qr/C=.*CN=.*/, "X509_NAME_oneline [2/3]");
  SKIP: {
    skip("cert order in CA chain is different in openssl pre-1.0.0", 2) unless Net::SSLeay::SSLeay >= 0x01000000;
    is(Net::SSLeay::X509_NAME_oneline($ca1_subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=Root CA', "X509_NAME_oneline [2/4]");
    is(Net::SSLeay::X509_NAME_oneline($ca2_subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=Intermediate CA', "X509_NAME_oneline [2/5]");
  }
}

{
  my($privkey, $cert, @cachain) = Net::SSLeay::P_PKCS12_load_file($filename3, 1);
  ok($privkey, '$privkey [3]');
  ok($cert, '$cert [3]');
  is(scalar(@cachain), 0, 'size of @cachain [3]');
  my $subj_name = Net::SSLeay::X509_get_subject_name($cert);
  is(Net::SSLeay::X509_NAME_oneline($subj_name), '/C=PL/O=Net-SSLeay/OU=Test Suite/CN=simple-cert.net-ssleay.example', "X509_NAME_oneline [3]");
}

{
  my($privkey, $cert, @should_be_empty) = Net::SSLeay::P_PKCS12_load_file($filename2, 0, $filename2_password);
  ok($privkey, '$privkey [4]');
  ok($cert, '$cert [4]');
  is(scalar(@should_be_empty), 0, 'size of @should_be_empty');
}
